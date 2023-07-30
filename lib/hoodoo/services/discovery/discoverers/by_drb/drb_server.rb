########################################################################
# File::    drb_server.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: For local development with no wider registration service
#           like MemCache running, the first service that gets started
#           will bring up a DRb server to record the location of other
#           services as they start up. The subsequent services connect
#           to the existing DRb server started by the first.
#
#           This class is almost a private implementation detail of
#           Hoodoo::Services::Middleware and is namespaced inside it.
#           File "service_middleware.rb" must be "require"'d first.
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb.
#           02-Mar-2015 (ADH): Moved into Discovery namespace.
########################################################################

require 'hoodoo'

require 'drb/drb'
require 'drb/acl'

module Hoodoo; module Services; class Discovery # Just used as a namespace here
  class ByDRb < Hoodoo::Services::Discovery # Also just used as a namespace here

    # A registry of service endpoints, implenented as a DRB server class. An
    # internal implementation detail of Hoodoo::Services::Middleware, in most
    # respects.
    #
    class DRbServer

      # URI for DRb server used during local machine development as a registry
      # of service endpoints. Whichever service starts first runs the server
      # which others connect to if subsequently started.
      #
      # +port+:: Optional integer port number for DRb service. If specified,
      #          this is used; else the +HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE+
      #          environment variable is used; else a default of 8787 is
      #          chosen. Passing +nil+ explicitly also leads to the use of
      #          the environment variable or default value.
      #
      def self.uri( port = nil )

        port ||= ENV[ 'HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE' ] || 8787

        # Use IP address, rather than 'localhost' here, to ensure that "address
        # in use" errors are raised immediately if a second server startup
        # attempt is made:
        #
        #   https://bugs.ruby-lang.org/issues/3052
        #
        "druby://127.0.0.1:#{ port }"

      end

      # Start the DRb server. Does not return (joins the DRb thread). If the
      # server is already running, expect an "address in use" connection
      # exception from DRb.
      #
      # +port+:: Passed to ::uri method.
      #
      def self.start( port = nil )

        uri = self.uri( port )

        $stop_queue = ::Queue.new

        ::DRb.start_service( uri,
                             FRONT_OBJECT,
                             :tcp_acl => LOCAL_ACL )

        # DRB.thread.exit() does not reliably work; sometimes, it just hangs
        # up. I don't know why. On OS X and under Travis, sporadic failures
        # to return from the "stop()" method would result. Instead, we use a
        # relatively elaborate queue; sit here waiting for a message to be
        # pushed onto it, then just let this method exit naturally, ignoring
        # the value that appeared on the queue.
        #
        # The sleep makes it more reliable too, indicating some kind of nasty
        # race condition on start-vs-wait-to-shutdown.

        sleep( 1 )
        $stop_queue.pop()
      end

      # Create an instance ready for use as a DRb "front object".
      #
      def initialize
        @repository = {}
      end

      # Check to see if this DRb service is awake. Returns +true+.
      #
      def ping
        return true
      end

      # Add an endpoint to the list. If the endpoint was already added,
      # it will be overwritten with the new data.
      #
      # +resource+:: Resource as a String or Symbol, e.g. "Product"
      # +version+::  Endpoint's implemented API version as an Integer, e.g. 1
      # +uri+::      URI at which this service may be accessed, including the
      #              endpoint path (e.g. "http://localhost:3002/v1/products"),
      #              as a String.
      #
      def add( resource, version, uri )
        @repository[ "#{ resource }/#{ version }" ] = uri
      end

      # Find an endpoint in the list. Returns URI at which the service may be
      # accessed as a String, or 'nil' if not found.
      #
      # +resource+:: Resource as a String or Symbol, e.g. "Product"
      # +version+::  Endpoint's implemented API version as an Integer, e.g. 1
      #
      def find( resource, version )
        @repository[ "#{ resource }/#{ version }" ]
      end

      # Flush out the repository, clearing all stored service records. This is
      # usually for test purposes only.
      #
      def flush
        @repository = {}
      end

      # Shut down this DRb service.
      #
      def stop
        $stop_queue.push( true )
      end
    end

    # Singleton "Front object" for the DRB service used in local development.
    #
    FRONT_OBJECT = Hoodoo::Services::Discovery::ByDRb::DRbServer.new

    # Only allow connections from 127.0.0.1.
    #
    LOCAL_ACL = ACL.new( %w[
      deny all
      allow ::1
      allow fe80::1%lo0
      allow 127.0.0.1
    ] )

  end
end; end; end
