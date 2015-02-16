########################################################################
# File::    service_registry_drb_server.rb
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
########################################################################

require 'hoodoo'

require 'drb/drb'
require 'drb/acl'

module Hoodoo; module Services
  class Middleware

    # A registry of service endpoints, implenented as a DRB server class. An
    # internal implementation detail of Hoodoo::Services::Middleware, in most
    # respects.
    #
    class ServiceRegistryDRbServer

      # URI for DRb server used during local machine development as a registry
      # of service endpoints. Whichever service starts first runs the server
      # which others connect to if subsequently started.
      #
      def self.uri

        # Use IP address, rather than 'localhost' here, to ensure that "address
        # in use" errors are raised immediately if a second server startup
        # attempt is made:
        #
        #   https://bugs.ruby-lang.org/issues/3052
        #
        "druby://127.0.0.1:#{ ENV[ 'HOODOO_MIDDLEWARE_DRB_PORT_OVERRIDE' ] || 8787 }"

      end

      # Start the DRb server. Does not return (joins the DRb thread). If the
      # server is already running, expect an "address in use" connection
      # exception from DRb.
      #
      def self.start
        drb_uri = self.uri()

        DRb.start_service( drb_uri,
                           FRONT_OBJECT,
                           :tcp_acl => LOCAL_ACL )

        DRb.thread.join()
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

      # Shut down this DRb service.
      #
      def stop
        DRb.thread.exit
      end
    end

    # For local development, a DRb service is used. We thus must
    # "disable eval() and friends":
    #
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/drb/rdoc/DRb.html
    #
    $SAFE = 1

    # Singleton "Front object" for the DRB service used in local development.
    #
    FRONT_OBJECT = Hoodoo::Services::Middleware::ServiceRegistryDRbServer.new

    # Only allow connections from 127.0.0.1.
    #
    LOCAL_ACL = ACL.new( [ 'deny', 'all', 'allow', '127.0.0.1' ] )

  end
end; end
