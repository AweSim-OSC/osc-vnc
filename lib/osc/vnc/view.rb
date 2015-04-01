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

      def initialize(args = {})
        # Files and paths
        @xstartup = args[:xstartup]
        @xlogout = args[:xlogout]
        @outdir = args[:outdir]

        # Batch server and cluster to be used
        batch = args[:batch]
        cluster = args[:cluster]

        # Read in VNC specific args for given batch system
        # merge any matching keys from args
        # and make methods out of them for Mustache
        view = YAML.load_file("#{CONFIG_PATH}/view.yml")
        view_cluster = YAML.load_file("#{CONFIG_PATH}/view_cluster.yml")
        default_args = view[batch].merge view_cluster[cluster]
        default_args.merge! args.select{|k| default_args.keys.include? k}
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
