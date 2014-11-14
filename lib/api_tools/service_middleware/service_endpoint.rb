########################################################################
# File::    service_endpoint.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of ApiTools::ServiceMiddleware in order to gain
#           access to middleware protected methods, this code is used
#           for inter-service calls. Instances of this class are given
#           to service action implementations through the +context+
#           variable, through ApiTools::ServiceContext#resource.
#
#           This class is almost a private implementation detail of
#           ApiTools::ServiceMiddleware and is namespaced inside it.
#           File "service_middleware.rb" must be "require"'d first.
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb.
########################################################################

module ApiTools
  class ServiceMiddleware

    # Representation of a callable service endpoint for a specific resource.
    # Services that wish to call other services should obtain an endpoint
    # instance via ApiTools::ServiceContext#resource then use the instance
    # methods described for this class to call other services. The calls they
    # use look very similar to the calls they implement for their own
    # instances. The response they get is in the form of an
    # ApiTools::ServiceResponse instance describing the inter-service call's
    # results.
    #
    class ServiceEndpoint < ApiTools::ServiceMiddleware

      # Find out the service interface class being used by this instance.
      # If +nil+, the interface is remote - it isn't part of the middleware
      # instance that owns the endpoint instance. The endpoint may not be
      # available, but you won't know until you try to talk to it over the
      # network.
      #
      def interface
        @local_service.nil? ? nil : @local_service[ :interface ]
      end

      # Create an endpoint instance on behalf of the given
      # ApiTools::ServiceMiddleware instance, directed at the given resource.
      #
      # +middleware_instance+:: ApiTools::ServiceMiddleware used to handle
      #                         onward requests.
      #
      # +resource+:: Resource name the endpoint targets, e.g. +:Purchase+.
      #              String or symbol.
      #
      # +version+::  Optional required interface (API) version for that
      #              endpoint. Integer. Default is 1.
      #
      # When calls are made through endpoints, the caller's call context data
      # is updated. The ApiTools::ServiceResponse instance in the context will
      # hold error details, if there were any. Callers must always check their
      # ApiTools::ServiceResponse#halt_processing? value and if +true+ should
      # exit early.
      #
      # Endpoint methods for listing, creating etc. resources have common
      # parameters some or all of which are used across the method 'family':
      #
      # +ident+::      An identifier. This is usually a UUID but some resources
      #                support e.g. a "show" action based on either a UUID or
      #                some other unique identifier. Currency, for example,
      #                can look up on a UUID or a currency code.
      #
      # +query_hash+:: A hash of unencoded data that could be encoded to form
      #                a query string. Search and filter data is represented
      #                with nested hashes. Embed and reference data uses an
      #                array. Example:
      #
      #                   {
      #                     offset: 75,
      #                     limit:  50,
      #                     search: {
      #                       member_id: "...some UUDI..."
      #                     },
      #                     _embed: [
      #                       'vouchers',
      #                       'balances'
      #                     ]
      #                   }
      #
      #                This parameter is always optional.
      #
      # +body_hash+::  The Hash representation of the body data that might be
      #                sent in an HTTP request (i.e. JSON, as a Hash).
      #
      def initialize( middleware_instance, resource, version = 1 )
        @middleware    = middleware_instance
        @resource      = resource.to_s
        @version       = version.to_i

        @local_service = @middleware.local_service_for( @resource, @version )
        @remote_uri    = @middleware.remote_service_for( @resource, @version )
      end

      # Obtain a list of resource instance representations.
      #
      # +query_hash+:: See #initialize. This is the only way to search/filter
      #                the list, according to the targer Resource's documented
      #                supported search/filter parameters and the platform's
      #                common all-resource behaviour.
      #
      # Returns an array of zero or more resource representations as Hashes,
      # unless there's an error (check the ApiTools::ServiceContext instance's
      # request object's ApiTools::ServiceResponse#halt_processing? value).
      #
      def list( query_hash = nil )
        @middleware.inter_service(
          :local       => @local_service,
          :remote      => @remote_uri,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'GET',
          :query_hash  => query_hash
        )
      end

      # Obtain a resource instance representation.
      #
      # +ident+::      See #intiialize.
      # +query_hash+:: See #initialize.
      #
      # Returns a Hash representation of a resource instance, unless there's an
      # error (check the ApiTools::ServiceContext instance's request object's
      # ApiTools::ServiceResponse#halt_processing? value).
      #
      def show( ident, query_hash = nil )
        @middleware.inter_service(
          :local       => @local_service,
          :remote      => @remote_uri,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'GET',
          :ident       => ident,
          :query_hash  => query_hash
        )
      end

      # Create a resource instance.
      #
      # +body_hash+::  See #intiialize.
      # +query_hash+:: See #initialize.
      #
      # Returns a Hash representation of the new resource instance, unless
      # there's an error (check the ApiTools::ServiceContext instance's request
      # object's ApiTools::ServiceResponse#halt_processing? value).
      #
      def create( body_hash, query_hash = nil )
        @middleware.inter_service(
          :local       => @local_service,
          :remote      => @remote_uri,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'POST',
          :body_hash   => body_hash,
          :query_hash  => query_hash
        )
      end

      # Update a resource instance.
      #
      # +ident+::      See #intiialize.
      # +body_hash+::  See #intiialize.
      # +query_hash+:: See #initialize.
      #
      # Returns a Hash representation of the updated resource instance, unless
      # there's an error (check the ApiTools::ServiceContext instance's request
      # object's ApiTools::ServiceResponse#halt_processing? value).
      #
      def update( ident, body_hash, query_hash = nil )
        @middleware.inter_service(
          :local       => @local_service,
          :remote      => @remote_uri,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'PATCH',
          :ident       => ident,
          :body_hash   => body_hash,
          :query_hash  => query_hash
        )
      end

      # Delete a resource instance.
      #
      # +ident+::      See #intiialize.
      # +query_hash+:: See #initialize.
      #
      # Returns a Hash representation of the now-deleted resource instance,
      # unless there's an error (check the ApiTools::ServiceContext instance's
      # request object's ApiTools::ServiceResponse#halt_processing? value).
      #
      def delete( ident, query_hash = nil )
        @middleware.inter_service(
          :local       => @local_service,
          :remote      => @remote_uri,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'DELETE',
          :ident       => ident,
          :query_hash  => query_hash
        )
      end

    end
  end
end
