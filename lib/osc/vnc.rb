require 'osc/vnc/version'
require 'osc/vnc/oxymoron'

require 'pbs'
require 'socket'

module OSC
  module VNC
    # Initialize PBS Ruby with special torque library for oxymoron cluster
    PBS.init TORQUE_LIB
  end
end

require 'osc/vnc/session'
