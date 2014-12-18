require "osc/vnc/version"

require "pbs"
require "socket"

module OSC
  class VNC
    # Systems
    SYSTEMS = %w(glenn oakley ruby)

    # Oxymoron torque library
    TORQUE_LIB = '/usr/local/torque-4.2.8/lib/libtorque.so'

    # Oxymoron batch server
    SERVER = 'oak-batch.osc.edu:17001'

    # VNC batch script
    BATCH_SCRIPT = File.expand_path(File.dirname(__FILE__)) + "/../../data/vnc.pbs"

    # Initialize PBS Ruby with special torque library for oxymoron cluster
    PBS.init TORQUE_LIB

    attr_accessor :name, :cluster, :outdir, :xdir, :xstartup, :xlogout, :walltime

    def initialize(options)
      @name = options[:name] || 'vnc'
      @cluster = options[:cluster] || 'glenn'
      @outdir = options[:outdir] || ENV['PWD']
      @xdir = options[:xdir]
      @xstartup = options[:xstartup] || 'xstartup'
      @xlogout = options[:xlogout] || 'xlogout'
      @walltime = options[:walltime] || '00:05:00'

      # Check for errors
      raise ArgumentError, "xstartup directory is undefined" unless xdir
      raise ArgumentError, "xstartup script is not found" unless File.file?("#{xdir}/#{xstartup}")
      raise ArgumentError, "output directory is a file" if File.file?(outdir)
      raise ArgumentError, "invalid cluster system" unless SYSTEMS.include?(cluster)
      raise ArugmentError, "invalid walltime" unless /^\d\d:\d\d:\d\d$/.match(walltime)
    end

    def run()
      # Make output directory if it doesn't already exist
      FileUtils.mkdir_p(outdir)

      # Connect to oxymoron cluster
      c = PBS.pbs_connect(SERVER)

      # Create PBS head
      attropl = create_head()

      # Submit new job
      pbsid = PBS.pbs_submit(c, attropl, "#{BATCH_SCRIPT}", nil, nil)

      # Disconnect after submission
      PBS.pbs_disconnect(c)

      # FIXME 
      puts pbsid
    end

    ########################################
    # Private methods
    ########################################

      def create_head()
        # Atrributes for VNC job
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
  end
end
