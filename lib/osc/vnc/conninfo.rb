include 'mustache'

module OSC
  module VNC
    class ConnInfo
      attr_reader :session

      def initialize(args)
        @session = args[:session]
      end

      Dir.glob("#{VIEWS}/*.mustache") do |file|
        basename = File.basename(file)
        type = File.basename(file, ".mustache")

        define_method(type.prepend("to_").to_sym) do
          template = "#{VIEWS}/ssh/#{basename}"
          if !session.view.ssh_tunnel? || !File.file?(template)
            template = file
          end

          string = nil
          File.open(template, 'r') do |f|
            string = Mustache.render(f.read, session)
          end
          string
        end
      end
    end
  end
end
