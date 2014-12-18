require "osc/vnc/version"

require 'pbs'
require 'socket'

# Path of script
PATH = File.expand_path(File.dirname(__FILE__))

module OSC
  module VNC
    def submit(options)
      # Make output directory if it doesn't already exist
      FileUtils.mkdir_p(options[:outdir])

      # Initialize PBS Ruby with special torque library for oxymoron cluster
      PBS.init '/usr/local/torque-4.2.8/lib/libtorque.so'

      # Connect to oxymoron cluster (note: must be on web services node)
      server = 'oak-batch.osc.edu:17001'
      c = PBS.pbs_connect(server)

      # Setup VNC job
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

      # Submit new job
      pbsid = PBS.pbs_submit(c, attropl, "#{PATH}/../../data/vnc.pbs", nil, nil)

      # Disconnect after submission
      PBS.pbs_disconnect(c)

      # Output jobid to stdout
      puts pbsid

    end
  end
end
