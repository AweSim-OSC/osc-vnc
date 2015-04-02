require 'mustache'
require 'yaml'

module OSC
  module VNC
    class View < Mustache
      self.template_file = "#{TEMPLATE_PATH}/vnc.mustache"

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
        view = YAML.load_file("#{CONFIG_PATH}/view.yml")
        raise ArgumentError, "invalid batch system" unless view.key? batch
        view_cluster = YAML.load_file("#{CONFIG_PATH}/view_cluster.yml")
        raise ArgumentError, "invalid cluster system" unless view_cluster.key? cluster
        default_args = view[batch].merge view_cluster[cluster]
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
