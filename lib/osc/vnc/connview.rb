require 'mustache'

module OSC
  module VNC
    # Provides a view for a variety of connection information templates in
    # templates/conn. Extra options can be passed to this view and accessed
    # directly in the mustache templates.
    class ConnView
      # @!attribute [r] session
      #   @return [Session] the session object with connection information
      attr_reader :session

      # @param [Hash] args the arguments used to construct a connection information view
      # @option args [Session] :session The session object with the connection information
      def initialize(args)
        @session = args[:session]
      end

      # FIXME: This method below needs to be cleaned up

      # @!method to_format
      #   Generates a string from a template depending on the format name,
      #   current options include (to_jnlp, to_awesim, to_terminal, to_txt,
      #   to_vnc, to_yaml) (see templates/conn/)
      #   @param [Hash] args the arguments are merged into the context used to
      #     generate the template of the connection information
      #   @return [String] the mustache generated view of the template
      Dir.glob("#{CONN_TEMPLATE_PATH}/*.mustache") do |template|
        type = File.basename(template, ".mustache")

        define_method(type.prepend("to_").to_sym) do |args = {}|
          string = nil
          File.open(template, 'r') do |f|
            context = {
              host: session.host,
              port: session.port,
              display: session.display,
              password: session.password,
              sshuser: ENV['USER'],
              sshhost: "#{session.cluster}.osc.edu",
              :'ssh?' => session.script_view.ssh_tunnel?
            }.merge args
            string = Mustache.render(f.read, context)
          end
          string
        end
      end
    end
  end
end
