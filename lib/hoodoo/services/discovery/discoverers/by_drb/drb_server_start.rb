########################################################################
# File::    drb_server_start.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Run the DRB server. See service_registry_drb_server.rb.
#           Usage:
#
#               bundle exec ruby drb_server_start.rb
#
#           There is usually no need to do this manually, as the
#           middleware does it for you automatically.
# ----------------------------------------------------------------------
#           23-Dec-2014 (ADH): Created.
########################################################################

require 'ostruct'
require 'optparse'

require 'hoodoo'

options = OpenStruct.new

OptionParser.new do |opts|
  opts.banner = 'Usage: drb_server_start.rb [options]'

  opts.on( '-p', '--port PORT', 'Listening port' ) do | val |
    options.port = val || ENV[ 'HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE' ] || 8787
  end

  opts.on( '-h', '--help', 'Prints this help' ) do
    puts opts
    exit
  end
end.parse!

Process.setsid()
Hoodoo::Services::Discovery::ByDRb::DRbServer.start( options.port )
