########################################################################
# File::    service_registry_drb_server_start.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Run the DRB server. See service_registry_drb_server.rb.
#           Usage:
#
#               bundle exec ruby service_registry_drb_server_start.rb
#
#           There is usually no need to do this manually, as the
#           middleware does it for you automatically.
# ----------------------------------------------------------------------
#           23-Dec-2014 (ADH): Created.
########################################################################

require 'hoodoo'

Process.setsid()
Hoodoo::ServiceMiddleware::ServiceRegistryDRbServer.start()
