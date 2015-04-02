require 'pbs'

module OSC
  module VNC
    # Define torque libraries
    TORQUE_OXYMORON_LIB = '/usr/local/torque-4.2.8/lib/libtorque.so'
    TORQUE_COMPUTE_LIB = '/usr/local/torque-2.4.10/lib/libtorque.so'

    # Template path
    TEMPLATE_PATH = File.dirname(__FILE__) + "/../../template"

    # Config path
    CONFIG_PATH = File.dirname(__FILE__) + "/../../config"

    # Views path
    VIEWS_PATH = File.dirname(__FILE__) + "/../../views"
  end
end

require 'osc/vnc/version'
require 'osc/vnc/session'
require 'osc/vnc/view'
require 'osc/vnc/conninfo'
