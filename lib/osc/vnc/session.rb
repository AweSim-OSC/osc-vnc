require 'yaml'
require 'fileutils'

require 'osc/vnc/listenable'

class OSC::VNC::Session
  include OSC::VNC::Listenable

  attr_accessor :batch, :cluster, :headers, :resources, :envvars
  attr_accessor :xstartup, :xlogout, :outdir, :options
  attr_accessor :pbsid, :host, :port, :display, :password
  attr_reader :view

  DEFAULT_ARGS = {
    # Batch setup information
    batch: "oxymoron",
    cluster: "glenn",
    headers: {},
    resources: {},
    envvars: {},
    # Batch template options
    xstartup: nil,
    xlogout: nil,
    outdir: ENV['PWD'],
    options: {}
  }

  def initialize(args)
    args = DEFAULT_ARGS.merge(args)

    # Batch setup information
    @batch = args[:batch]
    @cluster = args[:cluster]
    @headers = args[:headers]
    @resources = args[:resources]
    @envvars = args[:envvars]

    # Batch template args
    @xstartup = args[:xstartup]
    @xlogout = args[:xlogout]
    @outdir = args[:outdir]
    @options = args[:options]
  end

  # Default headers are generated based on user input
  def headers
    {
      PBS::Torque::ATTR[:N] => "VNC_Job",
      PBS::Torque::ATTR[:o] => "#{outdir}/$PBS_JOBID.output",
      PBS::Torque::ATTR[:j] => "oe",
      PBS::Torque::ATTR[:S] => "/bin/bash"
    }.merge @headers
  end

  def run()
    raise ArgumentError, "xstartup script is not found" unless File.file?(xstartup)
    raise ArgumentError, "output directory is a file" if File.file?(outdir)

    self.view = View.new(batch: batch, cluster: cluster, xstartup: xstartup,
                         xlogout: xlogout, outdir: outdir, options: options)

    # Create tcp listen server
    listen_server = nil
    listen_server = create_listen if view.tcp_server?

    # Make output directory if it doesn't already exist
    FileUtils.mkdir_p(outdir)

    # Connect to server and submit job with proper PBS attributes
    batch_server = YAML.load_file("#{CONFIG_PATH}/batch.yml")[batch][cluster]
    c = PBS::Conn.new(server: batch_server)
    j = PBS::Job.new(conn: c)
    self.pbsid = j.submit(string: view.render, headers: headers, resources: resources, envvars: envvars)

    # Get connection information
    _get_listen_conn_info(listen_server) if view.tcp_server?

    self
  end


  def _get_listen_conn_info(server)
    # Wait until VNC conn info is created by PBS batch script
    # Timeout after 30 seconds if no info is sent
    response = nil
    Timeout::timeout(30) { response = read_listen(server: server) }

    # Get connection info
    {:@host => 'Host', :@port => 'Port', :@display => 'Display', :@password => 'Pass'}.each do |key, value|
      instance_variable_set(key, /^#{value}: (.*)$/.match(response)[1])
      raise RuntimeError, "#{key} not specified by batch job" unless instance_variable_get(key)
    end
  end
end
