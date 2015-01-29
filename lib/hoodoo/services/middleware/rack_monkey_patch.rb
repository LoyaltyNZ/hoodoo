########################################################################
# File::    rack_monkey_patch.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Heyre Be Dragyns.
#
#           For local development, the service middleware needs to know
#           where other resource endpoints are in terms of HTTP host and
#           port, so that remote inter-resource calls can work without
#           up-front static configuration of service host/port data. To
#           have to manage a fixed list of local development ports in
#           the face of arbitrary resource endpoint divisions would be a
#           big pain and cause developers much frustration.
#
#           This means that whenever a service starts up, it needs to
#           know the HTTP host and port under which it is running, then
#           tell the middleware about it.
#
#           In the absence of a formal interface in Rack for this, then
#           we could do still that relatively nicely by looking up the
#           Rack server in ObjectSpace and asking it for its options -
#           except some of the web server adapters do really dumb things
#           like "options.delete(:Host)" to read items out, destroying
#           the info we need.
#
#           So instead, we have to monkey patch :-(
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb.
########################################################################

if defined?( Rack ) && defined?( Rack::Server )

  # Part of the Rack monkey patch. See file
  # "rack_monkey_path.rb"'s documentation for details.
  #
  module Rack

    # Part of the Rack monkey patch. See file
    # "rack_monkey_path.rb"'s documentation for details.
    #
    class Server

      class << self

        # Part of the Rack monkey patch. See file
        # "rack_monkey_path.rb"'s documentation for details.
        #
        # This method is aliased in place of Rack::Server::start and reads
        # the passed-in options hash to attempt to determine the host name
        # and port number under which a Rack based service is running. It
        # then calls through to Rack's original ::start implementation.
        #
        # +options+:: Options (see original Rack::Server documentation).
        #
        def start_and_record_host_and_port( options = nil )
          Hoodoo::Services::Middleware.record_host_and_port( options )
          racks_original_start( options )
        end

        # Part of the Rack monkey patch. Alias for the original
        # Rack::Server::start.
        #
        alias racks_original_start start

        # Part of the Rack monkey patch. See ::start_and_record_host_and_port.
        #
        # +options+:: See ::start_and_record_host_and_port.
        #
        alias start start_and_record_host_and_port
      end
    end
  end
end
