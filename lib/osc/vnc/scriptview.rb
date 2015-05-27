require 'mustache'
require 'yaml'

module OSC
  module VNC
    class ScriptView < Mustache
      self.template_file = "#{SCRIPT_TEMPLATE_PATH}/vnc.mustache"

      attr_accessor :load_turbovnc
      attr_accessor :xstartup
      attr_accessor :xlogout
      attr_accessor :outdir

      def initialize(args)
        # Files and paths
        @xstartup = args[:xstartup]
        @xlogout = args[:xlogout]
        @outdir = args[:outdir]

        # Batch server and cluster to be used
        # along with overriding user options
        batch = args[:batch]
        cluster = args[:cluster]
        options = args[:options]

        # Read in VNC specific args for given batch system
        # & cluster... Merge in user-defined options
        # and make methods out of them for Mustache
        script_cfg = YAML.load_file("#{CONFIG_PATH}/script.yml")
        raise ArgumentError, "invalid batch system" unless script_cfg.key? batch
        cluster_cfg = YAML.load_file("#{CONFIG_PATH}/script_cluster.yml")
        raise ArgumentError, "invalid cluster system" unless cluster_cfg.key? cluster
        default_args = script_cfg[batch].merge cluster_cfg[cluster]
        default_args.merge! options
        default_args.each do |k, v|
          define_singleton_method(k) { v }
        end
      end

      def xstartup_dir
        File.dirname xstartup
      end
    end
  end
end
