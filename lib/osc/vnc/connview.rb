require 'mustache'

module OSC
  module VNC
    # Provides a view for a variety of connection information templates in
    # templates/conn. Extra options can be passed to this view and accessed
    # directly in the mustache templates.
    class ConnView < Mustache
      self.template_path = CONN_TEMPLATE_PATH

      # @return [Session] the session object with connection information.
      attr_reader :session

      # @param [Hash] args the arguments used to construct a connection information view.
      # @option args [Session] :session The session object with the connection information
      def initialize(args)
        @session = args[:session]
      end

      # @!method render(format, context = {})
      #   Generates a string from a template depending on the format name,
      #   current options include (:jnlp, :awesim, :terminal, :txt, :vnc,
      #   :yaml) (see templates/conn/*.mustache).
      #   @param [Symbol] format the format the connection info will be displayed in
      #   @param [Hash] context the context to be applied to mustache template
      #   @return [String] the mustache generated view of the template

      # The user to use for the ssh connection.
      # @return [String] the current user
      def sshuser
        ENV['USER']
      end

      # The host to use for the ssh connection.
      # @return [String] the hostname for the login node
      def sshhost
        "#{session.cluster}.osc.edu"
      end

      # See if the method call exists in @session or @session.script_view.
      #
      # @param method_name the method name called
      # @param arguments the arguments to the call
      # @param block an optional block for the call
      def method_missing(method_name, *arguments, &block)
        if @session.respond_to? method_name
          @session.send method_name
        elsif @session.script_view.respond_to? method_name
          @session.script_view.send method_name
        else
          super
        end
      end

      # Checks if the method responds to an instance method, or is able to
      # proxy it to @session or @session.script_view.
      #
      # @param method_name the method name to check
      # @return [Boolean]
      def respond_to_missing?(method_name, include_private = false)
        if @session.respond_to? method_name
          true
        elsif @session.script_view.respond_to? method_name
          true
        else
          super
        end
      end
    end
  end
end
