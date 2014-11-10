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
#           ApiTools::ServiceMiddleware and is namespaced inside it.
#           File "service_middleware.rb" must be "require"'d first.
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb.
########################################################################

module ApiTools
  class ServiceMiddleware

    # A registry of service endpoints, implenented as a DRB server class. An
    # internal implementation detail of ApiTools::ServiceMiddleware, in most
    # respects.
    #
    class ServiceRegistryDRbServer

      def initialize
        @repository = {}
      end

      # Add an endpoint to the list.
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

    end
  end
end
