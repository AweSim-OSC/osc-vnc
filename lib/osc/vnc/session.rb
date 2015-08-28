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

      # @return [Batch] the batch server to use
      attr_accessor :batch

      # @return [String] the path to the VNC xstartup file
      attr_accessor :xstartup

      # @return [String] the path to the VNC xlogout file (which is run when job finishes)
      attr_accessor :xlogout

      # @return [String] the path the VNC output directory
      attr_accessor :outdir

      # @return [String] the PBS id for the submitted VNC job
      attr_accessor :pbsid

      attr_writer :headers, :resources, :envvars, :options

      # @param [Hash] args the arguments used to construct a session
      # @option args [Batch] :batch ('oxymoron') The batch server to run on ('glenn', 'oakley', 'ruby', 'oxymoron')
      # @option args [Hash] :headers The hash of PBS header attributes for the job
      # @option args [Hash] :resources The hash of PBS resources requested for the job
      # @option args [Hash] :envvars The hash of environment variables passed to the job
      # @option args [String] :xstartup The path to the VNC xstartup file (this is the main script that is run)
      # @option args [String] :xlogout The path the the VNC xlogout file (this script is run when job finishes)
      # @option args [String] :outdir (current working directory) The path where files are output to
      # @option args [Hash] :options The hash detailing all the VNC options (see config/script*.yml)
      # @option args [String] :pbsid The PBS id for a submitted VNC job (used to get conn info for job already submitted)
      def initialize(args)
        # Batch setup information
        @batch     = args[:batch] || Batch.new(name: 'oxymoron', cluster: 'glenn')
        @headers   = args[:headers] || {}
        @resources = args[:resources] || {}
        @envvars   = args[:envvars] || {}

        # Batch template args
        @xstartup = args[:xstartup]
        @xlogout  = args[:xlogout]
        @outdir   = args[:outdir] || ENV['PWD']
        @options  = args[:options] || {}

        # PBS connection info (typically discovered later)
        @pbsid    = args[:pbsid]
        @host     = args[:host]
        @port     = args[:port]
        @display  = args[:display]
        @password = args[:password]
      end

      # The hash of PBS header attributes for the job.
      #
      # @return [Hash] hash of headers merged with default headers
      def headers
        {
          PBS::ATTR[:N] => "VNC_Job",
          PBS::ATTR[:o] => "#{outdir}/$PBS_JOBID.output",
          PBS::ATTR[:j] => "oe",
          PBS::ATTR[:S] => "/bin/bash"
        }.merge @headers
      end

      # The hash of PBS resources requested for the job.
      #
      # @return [Hash] hash of resources merged with default resources
      def resources
        r = {}
        if batch.shared?
          r[:nodes] = "1:ppn=1"
          r[:nodes] += ":#{batch.cluster}" if batch.multicluster?
          r[:walltime] = "24:00:00"
        end
        r.merge @resources
      end

      # The hash of environment variables passed to the job.
      #
      # @return [Hash] hash of environment variables merged with default environment variables
      def envvars
        {
        }.merge @envvars
      end

      # The hash detailing all the VNC options (see config/script*.yml).
      #
      # @return [Hash] hash of VNC options merged with default options
      def options
        {
        }.merge @options
      end

      # Submit the VNC job to the defined batch server.
      #
      # @return [Session] the session object
      # @raise [InvalidPath] if {#xstartup} or {#outdir} do not correspond to actual file system locations
      def run()
        self.xstartup = File.expand_path xstartup
        self.xlogout = File.expand_path xlogout if xlogout
        self.outdir = File.expand_path outdir
        raise InvalidPath, "xstartup script is not found" unless File.file?(xstartup)
        raise InvalidPath, "output directory is a file" if File.file?(outdir)
        FileUtils.mkdir_p(outdir)

        # Create tcp listen server
        listen_server = _create_listen_server if script_view.tcp_server?

        # Connect to server and submit job with proper PBS attributes
        c = PBS::Conn.new(batch: batch)
        j = PBS::Job.new(conn: c)
        self.pbsid = j.submit(string: script_view.render, headers: headers,
                              resources: resources, envvars: envvars, qsub: true).id

        # Get connection information right away if using tcp server
        _write_listen_conn_info(listen_server) if script_view.tcp_server?

        self
      end

      # The connection information file.
      #
      # @return [String] path to connection information file for this session
      def conn_file
        "#{outdir}/#{pbsid}.conn"
      end

      # Create a view object for the PBS batch script mustache template
      # located: template/script/vnc.mustache.
      #
      # @return [ScriptView] view object used for PBS batch script mustache template
      # @see ScriptView
      def script_view
        ScriptView.new(batch: batch, xstartup: xstartup, xlogout: xlogout,
                       outdir: outdir, options: options)
      end


      private

      # Create a tcp listen server and set appropriate environment variables.
      # for batch script to phone home
      def _create_listen_server
        listen_server = create_listen
        _, port, host, _ = listen_server.addr(:hostname)
        @envvars.merge! LISTEN_HOST: host, LISTEN_PORT: port
        listen_server
      end

      # Write connection information from a TCP listening server.
      def _write_listen_conn_info(server)
        # Wait until VNC conn info is created by PBS batch script
        # Timeout after 60 seconds if no info is sent
        Timeout::timeout(60) do
          File.open(conn_file, 'w', 0600) { |f| f.puts read_listen(server: server) }
        end
      end
    end
  end
end
