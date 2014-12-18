require "osc/vnc/version"

require "pbs"
require "socket"

module OSC
  class VNC
    # Default options
    DEFAULT = {name: 'vnc', cluster: 'glenn', outdir: ENV['PWD'], xdir: nil,
               xstartup: 'xstartup', xlogout: 'xlogout', walltime: '00:05:00'}
    
    # Oxymoron torque library
    TORQUE_LIB = '/usr/local/torque-4.2.8/lib/libtorque.so'

    # Oxymoron batch server
    SERVER = 'oak-batch.osc.edu:17001'

    # VNC batch script
    BATCH_SCRIPT = File.expand_path(File.dirname(__FILE__)) + "/../../data/vnc.pbs"

    # Initialize PBS Ruby with special torque library for oxymoron cluster
    PBS.init TORQUE_LIB

    def initialize(options)
      options = DEFAULT.merge(options)

      # xstartup directory is required
      raise ArgumentError, "Directory of the xstartup script is undefined" unless options[:xdir]

      # Make output directory if it doesn't already exist
      FileUtils.mkdir_p(options[:outdir])

      # Output jobid to stdout
      puts submit(options)
    end

    ########################################
    # Private methods
    ########################################

      def create_head(options)
        # Atrributes for VNC job
        host = Socket.gethostname
        attropl = []
        attropl << {name: PBS::ATTR_N, value: options[:name]}
        attropl << {name: PBS::ATTR_l, resource: "walltime", value: options[:walltime]}
        attropl << {name: PBS::ATTR_l, resource: "nodes", value: "1:ppn=1:#{options[:cluster]}"}
        attropl << {name: PBS::ATTR_o, value: "#{host}:#{options[:outdir]}/$PBS_JOBID.output"}
        attropl << {name: PBS::ATTR_j, value: "oe"}
        attropl << {name: PBS::ATTR_M, value: "noreply@osc.edu"}
        attropl << {name: PBS::ATTR_S, value: "/bin/bash"}
        attropl << {name: PBS::ATTR_v, value: "OUTDIR=#{options[:outdir]},XSTARTUP_DIR=#{options[:xdir]}"}
        attropl
      end

      def submit(options)
        # Connect to oxymoron cluster
        c = PBS.pbs_connect(SERVER)

        # Create PBS head
        attropl = create_head(options)

        # Submit new job
        pbsid = PBS.pbs_submit(c, attropl, "#{BATCH_SCRIPT}", nil, nil)

        # Disconnect after submission
        PBS.pbs_disconnect(c)
        
        pbsid
      end
  end
end
