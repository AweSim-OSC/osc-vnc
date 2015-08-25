require 'mustache'
require 'yaml'
require 'forwardable'

module OSC
  module VNC
    # Provides a view for the PBS batch script configured as a mustache
    # template in templates/script/vnc.mustache. Extra options can be passed to
    # this view and accessed directly in the mustache template.
    class ScriptView < Mustache
      extend Forwardable

      self.template_file = "#{SCRIPT_TEMPLATE_PATH}/vnc.mustache"

      # @!attribute batch
      #   @return [Batch] the type of batch server to use
      attr_reader :batch

      # Constructs a new view for the PBS batch script template
      #
      # @param [Hash] args the arguments used to construct PBS batch script view
      # @option args [Batch] :batch the batch server job will run on ('glenn', 'oakley', 'ruby', 'oxymoron')
      # @option args [String] :xstartup the path of the VNC xstartup script (main script that is run)
      # @option args [String] :xlogout the path of the VNC xlogout script (script run when job finishes)
      # @option args [String] :outdir the output directory path
      # @option args [Hash] :options the hash describing any other options utilized by the batch script template
      def initialize(args = {})
        @batch = args[:batch]

        # Merge all arguments passed in as data for the view and template.
        @view_context = {}
        @view_context[:xstartup] = args[:xstartup]
        @view_context[:xlogout]  = args[:xlogout]
        @view_context[:outdir]   = args[:outdir]
        @view_context.merge!(args[:options] || {})

        # Read in VNC specific args depending if shared node or not
        script_cfg = YAML.load_file("#{CONFIG_PATH}/script.yml")
        if batch.shared?
          @view_context = script_cfg['shared'].merge @view_context
        else
          @view_context = script_cfg['default'].merge @view_context
        end
      end

      # Based on the xstartup path, also display directory to this file.
      def xstartup_dir
        File.dirname xstartup
      end

      # @!method fonts
      #   The fonts used by the vnc server.
      #   @return [String] The fonts
      #   @see Batch#fonts
      # @!method load_turbovnc
      #   The bash command used to load turbovnc
      #   @return [String] The bash command to load turbovnc module
      #   @see Batch#load_turbovnc
      def_delegators :batch, :fonts, :load_turbovnc

      # See if the method call exists as a key in @view_context.
      #
      # @param method_name the method name called
      # @param arguments the arguments to the call
      # @param block an optional block for the call
      def method_missing(method_name, *arguments, &block)
        @view_context.fetch(method_name) { @view_context.fetch(method_name.to_s) { super }}
      end

      # Checks if the method responds to an instance method, or is able to
      # proxy it to @view_context.
      #
      # @param method_name the method name to check
      # @return [Boolean]
      def respond_to_missing?(method_name, include_private = false)
        @view_context.include?(method_name) || @view_context.include?(method_name.to_s) || super
      end
    end
  end
end
