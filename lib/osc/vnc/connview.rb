require 'mustache'

module OSC
  module VNC
    class ConnView
      attr_reader :session

      def initialize(args)
        @session = args[:session]
      end

      Dir.glob("#{CONN_TEMPLATE_PATH}/*.mustache") do |template|
        basename = File.basename(template)
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
              sshhost: "#{session.cluster}.osc.edu"
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
