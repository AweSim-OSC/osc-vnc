module OSC::VNC::Listenable

  attr_accessor :listen_server, :listen_port

  def create_listen_server
    # Listen on random port
    @listen_server = TCPServer.new(0)
    @listen_port = @listen_server.addr[1]
  end

  def read_from_listen_server
    client = listen_server.accept   # wait for connection
    client.read                     # read complete response
  end

end
