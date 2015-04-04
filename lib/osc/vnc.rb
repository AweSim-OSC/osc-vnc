require 'pbs'

module OSC
  module VNC
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
