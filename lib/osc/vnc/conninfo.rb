require 'mustache'

module OSC
  module VNC
    class ConnInfo
      attr_reader :session

      def initialize(args)
        @session = args[:session]
      end

      Dir.glob("#{VIEWS_PATH}/*.mustache") do |file|
        basename = File.basename(file)
        type = File.basename(file, ".mustache")

        define_method(type.prepend("to_").to_sym) do
          template = "#{VIEWS_PATH}/ssh/#{basename}"
          if !session.view.ssh_tunnel? || !File.file?(template)
            template = file
          end

          string = nil
          File.open(template, 'r') do |f|
            context = {
              host: session.host,
              port: session.port,
              display: session.display,
              password: session.password,
              sshuser: ENV['USER'],
              sshhost: "#{session.cluster}.osc.edu"
            }
            string = Mustache.render(f.read, context)
          end
          string
        end
      end
    end
  end
end
