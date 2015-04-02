require 'socket'

module OSC
  module VNC
    module Listenable
      # Listen on random port
      def create_listen
        host = Socket.gethostname
        port = _get_port
        begin
          server = TCPServer.new(host, port)
        rescue Errno::EADDRINUSE
          listen_port = _get_port
          retry
        end
        server
      end

      def read_listen(args)
        server = args[:server]
        client = server.accept  # wait for connection
        client.read             # read complete response
      end

      # Get random number form 40,000 to 50,000
      def _get_port
        rand(40000..50000)
      end
    end
  end
end
