require 'fileutils'

require 'osc/vnc/listenable'

module OSC
  module VNC
    # Provides a way for developers to create and submit VNC sessions to the
    # OSC batch systems. Also, developers are now able to submit any server
    # session to the batch systems whether it is VNC or not following the same
    # principles as a VNC session.
    class Session
      include OSC::VNC::Listenable

      # @!attribute batch
      #   @return [String] the type of batch server to use ('oxymoron' or 'compute')
      attr_accessor :batch

      # @!attribute cluster
      #   @return [String] the cluster to use ('glenn', 'oakley', 'ruby')
      attr_accessor :cluster

      # @!attribute headers
      #   @return [Hash] the hash of PBS header attributes for job
      attr_accessor :headers

      # @!attribute resources
      #   @return [Hash] the hash of PBS resources requested for job
      attr_accessor :resources

      # @!attribute envvars
      #   @return [Hash] the hash of environment variables passed to the job
      attr_accessor :envvars

      # @!attribute options
      #   @return [Hash] the hash detailing all the VNC options (see config/script*.yml)
      attr_accessor :options

      # @!attribute xstartup
      #   @return [String] the path to the VNC xstartup file
      attr_accessor :xstartup

      # @!attribute xlogout
      #   @return [String] the path to the VNC xlogout file (which is run when job finishes)
      attr_accessor :xlogout

      # @!attribute outdir
      #   @return [String] the path the VNC output directory
      attr_accessor :outdir

      # @!attribute pbsid
      #   @return [String] the PBS id for the submitted VNC job
      attr_accessor :pbsid

      # @!attribute host
      #   @return [String] the host specified in the VNC connection information
      attr_accessor :host

      # @!attribute port
      #   @return [String] the port specified in the VNC connection information
      attr_accessor :port

      # @!attribute display
      #   @return [String] the display port specified in the VNC connection information
      attr_accessor :display

      # @!attribute password
      #   @return [String] the password specified in the VNC connection information
      attr_accessor :password

      DEFAULT_ARGS = {
        # Batch setup information
        batch: 'oxymoron',
        cluster: 'glenn',
        # Batch template options
        xstartup: nil,
        xlogout: nil,
        outdir: ENV['PWD'],
      }

      # @param [Hash] args the arguments used to construct a session
      # @option args [String] :batch ('oxymoron') The type of batch server to run on ('oxymoron' or 'compute')
      # @option args [String] :cluster ('glenn') The OSC cluster to run on ('glenn', 'oakley', or 'ruby')
      def initialize(args)
        args = DEFAULT_ARGS.merge(args)

        # Batch setup information
        @batch     = args[:batch]
        @cluster   = args[:cluster]
        @headers   = args[:headers] || {}
        @resources = args[:resources] || {}
        @envvars   = args[:envvars] || {}

        # Batch template args
        @xstartup = args[:xstartup]
        @xlogout  = args[:xlogout]
        @outdir   = args[:outdir]
        @options  = args[:options] || {}

        # PBS connection info (typically discovered later)
        @pbsid    = args[:pbsid]
        @host     = args[:host]
        @port     = args[:port]
        @display  = args[:display]
        @password = args[:password]
      end

      def headers
        {
          PBS::ATTR[:N] => "VNC_Job",
          PBS::ATTR[:o] => "#{outdir}/$PBS_JOBID.output",
          PBS::ATTR[:j] => "oe",
          PBS::ATTR[:S] => "/bin/bash"
        }.merge @headers
      end

      def resources
        {
        }.merge @resources
      end

      def envvars
        {
        }.merge @envvars
      end

      def options
        {
        }.merge @options
      end

      # Submit the VNC job to the defined batch server
      #
      # @return [Session] the session object
      # @raise [ArgumentError] if {#xstartup} or {#outdir} do not correspond to actual file system locations
      def run()
        self.xstartup = File.expand_path xstartup
        self.xlogout = File.expand_path xlogout if xlogout
        self.outdir = File.expand_path outdir
        raise ArgumentError, "xstartup script is not found" unless File.file?(xstartup)
        raise ArgumentError, "output directory is a file" if File.file?(outdir)

        # Create tcp listen server
        listen_server = nil
        listen_server = _create_listen_server if script_view.tcp_server?

        # Make output directory if it doesn't already exist
        FileUtils.mkdir_p(outdir)

        # Connect to server and submit job with proper PBS attributes
        c = PBS::Conn.new(cluster: cluster, batch: batch)
        j = PBS::Job.new(conn: c)
        self.pbsid = j.submit(string: script_view.render, headers: headers, resources: resources, envvars: envvars, qsub: true).id

        # Get connection information right away if using tcp server
        _get_listen_conn_info(listen_server) if script_view.tcp_server?

        self
      end

      # Get connection info from file generated by PBS batch
      # job (read template/script/vnc.mustache)
      #
      # @return [Session] the session object
      def refresh_conn_info
        conn_file = "#{outdir}/#{pbsid}.conn"
        _get_file_conn_info(conn_file)
        self
      end

      # Create a view object for the PBS batch script mustache template
      # located: template/script/vnc.mustache
      #
      # @return [ScriptView] view object used for PBS batch script mustache template
      def script_view
        ScriptView.new(batch: batch, cluster: cluster, xstartup: xstartup,
                       xlogout: xlogout, outdir: outdir, options: options)
      end


      private

      # Get connection information from a file
      def _get_file_conn_info(file)
        raise RuntimeError, "connection file doesn't exist" unless File.file?(file)
        _parse_conn_info File.read(file)
      end

      # Create a tcp listen server and set appropriate
      # environment variables for batch script to phone home
      def _create_listen_server
        listen_server = create_listen
        _, port, host, _ = listen_server.addr(:hostname)
        envvars.merge! LISTEN_HOST: host, LISTEN_PORT: port
        listen_server
      end

      # Get connection information from a TCP listening server
      def _get_listen_conn_info(server)
        # Wait until VNC conn info is created by PBS batch script
        # Timeout after 30 seconds if no info is sent
        Timeout::timeout(30) { _parse_conn_info read_listen(server: server) }
      end

      # Parse out connection info from a string
      def _parse_conn_info(string)
        {:@host => 'Host', :@port => 'Port', :@display => 'Display', :@password => 'Pass'}.each do |key, value|
          match = /^#{value}: (.*)$/.match(string)
          raise RuntimeError, "#{key} not specified by batch job" unless match
          instance_variable_set(key, match[1].empty? ? nil : match[1])
        end
      end
    end
  end
end
