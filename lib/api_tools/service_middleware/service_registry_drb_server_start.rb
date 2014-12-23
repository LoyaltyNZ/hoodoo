########################################################################
# File::    service_registry_drb_server_start.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Run the DRB server. See service_registry_drb_server.rb.
#           Usage:
#
#               bundle exec ruby service_registry_drb_server_start.rb
#
# ----------------------------------------------------------------------
#           23-Dec-2014 (ADH): Created.
########################################################################

require 'api_tools'

Process.setsid()
ApiTools::ServiceMiddleware::ServiceRegistryDRbServer.start()
