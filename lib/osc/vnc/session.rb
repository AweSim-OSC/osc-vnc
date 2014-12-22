require 'osc/vnc/formattable'

class OSC::VNC::Session
  # Systems
  SYSTEMS = %w(glenn oakley ruby)

  # VNC batch script
  BATCH_SCRIPT = File.expand_path(File.dirname(__FILE__)) + "/../../../data/vnc.pbs"

  include OSC::VNC::Formattable

  attr_accessor :name, :cluster, :outdir, :xdir, :xstartup, :xlogout, :walltime
  attr_accessor :pbsid, :host, :port, :display, :password

  def initialize(options)
    @name = options[:name] || 'vnc'
    @cluster = options[:cluster] || 'glenn'
    @outdir = options[:outdir] || ENV['PWD']
    @xdir = options[:xdir]
    @xstartup = options[:xstartup] || 'xstartup'
    @xlogout = options[:xlogout] || 'xlogout'
    @walltime = options[:walltime] || '00:05:00'
  end

  def run()
    # Check for errors
    raise ArgumentError, "xstartup directory is undefined" unless xdir
    raise ArgumentError, "xstartup script is not found" unless File.file?("#{xdir}/#{xstartup}")
    raise ArgumentError, "output directory is a file" if File.file?(outdir)
    raise ArgumentError, "invalid cluster system" unless SYSTEMS.include?(cluster)
    raise ArugmentError, "invalid walltime" unless /^\d\d:\d\d:\d\d$/.match(walltime)

    # Make output directory if it doesn't already exist
    FileUtils.mkdir_p(outdir)

    # Connect to server and submit job with proper PBS attributes
    c = PBS.pbs_connect(OSC::VNC::SERVER)
    attropl = create_attr()
    self.pbsid = PBS.pbs_submit(c, attropl, "#{BATCH_SCRIPT}", nil, nil)
    PBS.pbs_disconnect(c)

    # Get connection information
    get_conn_info()

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

    def create_attr()
      # PBS attributes for a VNC job
      host = Socket.gethostname
      attropl = []
      attropl << {name: PBS::ATTR_N, value: name}
      attropl << {name: PBS::ATTR_l, resource: "walltime", value: walltime}
      attropl << {name: PBS::ATTR_l, resource: "nodes", value: "1:ppn=1:#{cluster}"}
      attropl << {name: PBS::ATTR_o, value: "#{host}:#{outdir}/$PBS_JOBID.output"}
      attropl << {name: PBS::ATTR_j, value: "oe"}
      attropl << {name: PBS::ATTR_M, value: "noreply@osc.edu"}
      attropl << {name: PBS::ATTR_S, value: "/bin/bash"}
      attropl << {name: PBS::ATTR_v, value: "OUTDIR=#{outdir},XDIR=#{xdir},XSTARTUP=#{xstartup},XLOGOUT=#{xlogout}"}
      attropl
    end

    def get_conn_info()
      conn_file = "#{outdir}/#{pbsid}.conn"

      # Wait until file is created
      wait_for_file conn_file

      File.open(conn_file) { |f|
        contents = f.read

        # Get connection info
        {:@host => 'Host', :@port => 'Port', :@display => 'Display', :@password => 'Pass'}.each do |key, value|
          instance_variable_set(key, /^#{value}: (.*)$/.match(contents)[1])
          raise RuntimeError, "#{key} not specified by batch job" unless instance_variable_get(key)
        end
      }

      # Remove connection info file when done
      File.delete(conn_file)
    end

    def wait_for_file(file)
      sleep_time = 0.1
      max_time = 30
      max_count = (max_time / sleep_time).ceil

      count = 0
      until File.exist?(file) || count == max_count
        count += 1
        sleep(sleep_time)
        `ls` #FIXME: dirty trick to flush file system cache
      end

      raise RuntimeError, "connection file was never created" if count == max_count
    end
end
