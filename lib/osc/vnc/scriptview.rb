require 'fileutils'
require 'mustache'
require 'yaml'

module OSC
  module VNC
    # Provides a view for the PBS batch script configured as a mustache
    # template in templates/script/vnc.mustache. Extra options can be passed to
    # this view and accessed directly in the mustache template.
    class ScriptView < Mustache
      self.template_path = SCRIPT_TEMPLATE_PATH

      # @param type [Symbol] The script type defined in config/script.yml (:vnc or :server).
      # @param cluster [String] The cluster the job will run on defined in config/cluster.yml.
      # @param opts [Hash] The options used to construct PBS batch script view.
      def initialize(type, cluster, opts = {})
        self.template_name = type

        # Read in pre-configured options
        script_cfg = YAML.load_file("#{CONFIG_PATH}/script.yml").fetch(type.to_s, {})
        subtype_opts = script_cfg[opts[:subtype].to_s] || script_cfg['default']
        cluster_opts = subtype_opts.fetch('cluster', {}).fetch(cluster, {})
        context = subtype_opts.merge cluster_opts

        @view_context = {}
        context.each do |key, value|
          @view_context[key.to_sym] = value
        end
        @view_context.merge! opts
        @view_context[:cluster] = cluster
      end

      # Determine whether the script is valid or not
      #
      # @return [Boolean] Whether this is a valid script.
      # @raise [InvalidPath] if {#xstartup} or {#outdir} do not correspond to actual file system locations
      def valid?
        raise InvalidPath, "xstartup script is not found" unless File.file?(xstartup)
        raise InvalidPath, "output directory is a file" if File.file?(outdir)
        FileUtils.mkdir_p(outdir)
      end

      # See if the method call exists as a key in @view_context.
      #
      # @param method_name the method name called
      # @param arguments the arguments to the call
      # @param block an optional block for the call
      def method_missing(method_name, *arguments, &block)
        @view_context.fetch(method_name) { super }
      end

      # Checks if the method responds to an instance method, or is able to
      # proxy it to @view_context.
      #
      # @param method_name the method name to check
      # @return [Boolean]
      def respond_to_missing?(method_name, include_private = false)
        @view_context.include?(method_name) || super
      end
    end
  end
end
