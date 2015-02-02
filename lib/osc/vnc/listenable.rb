module OSC::VNC::Listenable

  attr_accessor :listen_server, :listen_port

  def create_listen_server
    # Listen on random port
    @listen_port = get_port
    begin
      puts @listen_port
      @listen_server = TCPServer.new(@listen_port)
    rescue Errno::EADDRINUSE
      @listen_port = get_port
      retry
    end
  end

  def read_from_listen_server
    client = listen_server.accept   # wait for connection
    client.read                     # read complete response
  end

  private

    def get_port
      # Get random number form 40,000 to 50,000
      rand(40000..50000)
    end

end
