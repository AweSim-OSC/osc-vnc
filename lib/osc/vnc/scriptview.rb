require 'mustache'
require 'yaml'

module OSC
  module VNC
    # Provides a view for the PBS batch script configured as a mustache
    # template in templates/script/vnc.mustache. Extra options can be passed to
    # this view and accessed directly in the mustache template.
    class ScriptView < Mustache
      self.template_file = "#{SCRIPT_TEMPLATE_PATH}/vnc.mustache"

      # Constructs a new view for the PBS batch script template
      #
      # @param [Hash] args the arguments used to construct PBS batch script view
      # @option args [String] :xstartup the path of the VNC xstartup script (main script that is run)
      # @option args [String] :xlogout the path of the VNC xlogout script (script run when job finishes)
      # @option args [String] :outdir the output directory path
      # @option args [String] :batch the type of batch system job will run on ('oxymoron' or 'compute')
      # @option args [String] :cluster the OSC cluster the job will run on ('glenn', 'oakley', 'ruby')
      # @option args [Hash] :options the hash describing any other options utilized by the batch script template
      def initialize(args = {})
        # Merge all arguments passed in as data for the view and template
        @view_data = {}
        @view_data[:xstartup] = args[:xstartup]
        @view_data[:xlogout]  = args[:xlogout]
        @view_data[:outdir]   = args[:outdir]
        @view_data[:batch]    = args[:batch]
        @view_data[:cluster]  = args[:cluster]
        @view_data.merge!(args[:options] || {})

        # Read in VNC specific args for given batch system & cluster
        script_cfg = YAML.load_file("#{CONFIG_PATH}/script.yml")
        raise ArgumentError, "invalid batch system" unless script_cfg.include? batch
        cluster_cfg = YAML.load_file("#{CONFIG_PATH}/script_cluster.yml")
        raise ArgumentError, "invalid cluster system" unless cluster_cfg.include? cluster

        # Merge in these args keeping user args as priority
        @view_data = script_cfg[batch].merge @view_data
        @view_data = cluster_cfg[cluster].merge @view_data
      end

      # Based on the xstartup path, also display directory to this file
      # @api private
      def xstartup_dir
        File.dirname xstartup
      end

      # Turn all key-value pairs in @view_data into methods
      # @api private
      def method_missing(method_name, *arguments, &block)
        @view_data.fetch(method_name) { @view_data.fetch(method_name.to_s) { super } }
      end

      # This method follows from #method_missing
      # @api private
      def respond_to?(method_name, include_private = false)
        @view_data.include?(method_name) || @view_data.include?(method_name.to_s) || super
      end
    end
  end
end
