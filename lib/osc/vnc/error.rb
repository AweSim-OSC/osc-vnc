module OSC
  module VNC
    # Error used when a file or directory is invalid.
    class InvalidPath < StandardError; end

    # Error used when the connection information provided in the connection
    # information file is invalid.
    class InvalidConnInfo < StandardError; end
  end
end
