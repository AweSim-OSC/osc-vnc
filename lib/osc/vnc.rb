require 'pbs'

module OSC
  module VNC
    # Define torque libraries
    TORQUE_OXYMORON_LIB = '/usr/local/torque-4.2.8/lib/libtorque.so'
    TORQUE_COMPUTE_LIB = '/usr/local/torque-2.4.10/lib/libtorque.so'

    # Config path
    CONFIG_PATH = File.dirname(__FILE__) + "/../../config"

    # Template path
    SCRIPT_TEMPLATE_PATH = File.dirname(__FILE__) + "/../../templates/script"

    # Views path
    CONN_TEMPLATE_PATH = File.dirname(__FILE__) + "/../../templates/conn"
  end
end

require 'osc/vnc/version'
require 'osc/vnc/session'
require 'osc/vnc/scriptview'
require 'osc/vnc/connview'
