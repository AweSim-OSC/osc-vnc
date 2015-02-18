require 'osc/vnc/formattable'
require 'osc/vnc/listenable'
require 'fileutils'

class OSC::VNC::Session
  # Systems
  SYSTEMS = %w(glenn oakley ruby)

  # VNC batch script
  BATCH_SCRIPT = File.expand_path(File.dirname(__FILE__)) + "/../../../data/vnc.pbs"

  include OSC::VNC::Formattable
  include OSC::VNC::Listenable

  DEFAULT = {
    name: 'vnc',
    cluster: 'glenn',
    walltime: '00:05:00',
    outdir: ENV['PWD'],
    xdir: nil,
    xstartup: 'xstartup',
    xlogout: 'xlogout'
  }

  attr_accessor :opts
  attr_accessor :pbsid, :host, :port, :display, :password

  # Any options passed to the constructor become environment
  # variables in the batch script
  # Example:
  #   Session.new(cluster: 'oakley', xdir: '/path/to/xstartup', module: 'comsol/5.3')
  #   becomes in the batch script
  #   => $CLUSTER, $XDIR, $MODULE, and any other defaults defined above
  def initialize(options)
    @opts = DEFAULT.merge(options)
  end

  # Run the VNC session using Oxymoron batch queue
  def run()
    # Check for errors in user supplied options
    check_arg_errors

    # Create callback for PBS script
    create_pbs_callback

    # Make output directory if it doesn't already exist
    FileUtils.mkdir_p(opts[:outdir])

    # Connect to server and submit job with proper PBS attributes
    c = PBS.pbs_connect(OSC::VNC::SERVER)
    attropl = create_attr()
    self.pbsid = PBS.pbs_submit(c, attropl, "#{BATCH_SCRIPT}", nil, nil)
    PBS.pbs_disconnect(c)

    # Get connection information
    get_conn_info

    self
  end

  def to_s()
    # Output as string
    <<-EOF.gsub /^\s+/, ''
      PBSid: #{pbsid}
      Host: #{host}
      Port: #{port}
      Pass: #{password}
      Display: #{display}
    EOF
  end

  def url()
    # Output as a URL --- future placeholder
    "http://#{host}:#{port}/vnc_auto.html?password=#{password}"
  end

  ########################################
  # Private methods
  ########################################

    def check_arg_errors()
      # Check for errors with any of the user supplied arguments
      raise ArgumentError, "xstartup directory is undefined" unless opts[:xdir]
      raise ArgumentError, "xstartup script is not found" unless File.file?("#{opts[:xdir]}/#{opts[:xstartup]}")
      raise ArgumentError, "output directory is a file" if File.file?(opts[:outdir])
      raise ArgumentError, "invalid cluster system" unless SYSTEMS.include?(opts[:cluster])
      raise ArugmentError, "invalid walltime" unless /^\d\d:\d\d:\d\d$/.match(opts[:walltime])
    end

    def create_attr()
      # Convert extra options to comma delimited environment variable list
      pbs_vars = opts.map { |k,v| "#{k.upcase}=#{v}" }.join(",")

      # PBS attributes for a VNC job
      localhost = Socket.gethostname
      attropl = []
      attropl << {name: PBS::ATTR_N, value: opts[:name]}
      attropl << {name: PBS::ATTR_l, resource: "walltime", value: opts[:walltime]}
      attropl << {name: PBS::ATTR_l, resource: "nodes", value: "1:ppn=1:#{opts[:cluster]}"}
      attropl << {name: PBS::ATTR_o, value: "#{localhost}:#{opts[:outdir]}/$PBS_JOBID.output"}
      attropl << {name: PBS::ATTR_j, value: "oe"}
      attropl << {name: PBS::ATTR_M, value: "noreply@osc.edu"}
      attropl << {name: PBS::ATTR_S, value: "/bin/bash"}
      attropl << {name: PBS::ATTR_v, value: "#{pbs_vars}"}
      attropl
    end

    def get_conn_info()
      conn_file = "#{opts[:outdir]}/#{pbsid}.conn"

      # Wait until VNC conn info is created by PBS batch script
      response = wait_for_conn_info

      # Get connection info
      {:@host => 'Host', :@port => 'Port', :@display => 'Display', :@password => 'Pass'}.each do |key, value|
        instance_variable_set(key, /^#{value}: (.*)$/.match(response)[1])
        raise RuntimeError, "#{key} not specified by batch job" unless instance_variable_get(key)
      end
    end

    def create_pbs_callback()
      # Create a listen server and pass listen server info to
      # PBS batch script, so it can callback with VNC conn info
      create_listen_server
      self.opts[:listen_host] = Socket.gethostname
      self.opts[:listen_port] = listen_port
    end

    def wait_for_conn_info()
      # Read data from listen server
      data = nil
      Timeout::timeout(30) { data = read_from_listen_server }
      data
    end
end
