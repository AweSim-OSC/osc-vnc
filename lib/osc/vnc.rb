require 'pbs'

# The namespace used for OSC gems.
module OSC
  # The main namespace for osc-vnc. Provides the ability to submit and read back
  # the connection information for a VNC job on the OSC clusters.
  module VNC
    # Path to configuration yml files.
    CONFIG_PATH = File.dirname(__FILE__) + "/../../config"

    # Patch to PBS script template.
    SCRIPT_TEMPLATE_PATH = File.dirname(__FILE__) + "/../../templates/script"

    # Path to different connection information view templates.
    CONN_TEMPLATE_PATH = File.dirname(__FILE__) + "/../../templates/conn"
  end
end

require_relative 'vnc/version'
require_relative 'vnc/error'
require_relative 'vnc/session'
require_relative 'vnc/scriptview'
require_relative 'vnc/connview'
