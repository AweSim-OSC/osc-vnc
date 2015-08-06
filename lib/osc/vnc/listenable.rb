require 'socket'


module OSC
  module VNC
    # Mixin that adds the ability to create and read from a TCP server.
    module Listenable
      # Generate a TCP server that listens on a random port.
      #
      # @return [TCPServer] ruby TCPServer object listening on random port
      def create_listen
        listen_host = Socket.gethostname
        listen_port = _get_port
        begin
          server = TCPServer.new(listen_host, listen_port)
        rescue Errno::EADDRINUSE
          listen_port = _get_port
          retry
        end
        server
      end

      # Read the data received by the TCP server.
      #
      # @param [Hash] args the arguments to read data received by TCP server with
      # @option args [TCPServer] :server the TCP server that is currently listening
      # @return [String] the contents of the data received by the server
      def read_listen(args)
        server = args[:server]
        client = server.accept  # wait for connection
        client.read             # read complete response
      end


      private

      # Get random number form 40,000 to 50,000.
      #
      # @return [Fixnum] a random number from 40,000 to 50,000
      def _get_port
        rand(40000..50000)
      end
    end
  end
end
