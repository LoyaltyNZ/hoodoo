########################################################################
# File::    service_endpoint.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of ApiTools::ServiceMiddleware in order to gain
#           access to middleware protected methods, this code is used
#           for inter-resource calls. Instances of this class are given
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
    # When the implementation of one resource endpoint wants to perform an
    # operation on another resource, it should obtain an endpoint instance
    # via ApiTools::ServiceContext#resource then use the instance methods
    # described for this class to communicate with the other resource.
    #
    # In the case where the resource implementations exist in different
    # service applications, this is the only high level way for one resource
    # to talk to another.
    #
    # In the case where both resource implementations are held in the same
    # service application, this isn't strictly necessary. The implementation
    # code most likely has access to the same database tables so one could
    # directly look up data for another. That is however not recommended
    # unless profiling shows that it's required for performance reasons;
    # ideally you should *only* use the defined resource's API and thus keep
    # your resource implementation data layers decoupled from one another.
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
      # The instance is then used with the #list, #show, #create, #update or
      # #delete methods to perform operations on the target resource. See
      # each of those methods for details of their specific requirements;
      # however all have common parameters some or all of which are used
      # across the method 'family':
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
        @remote_info   = @middleware.remote_service_for( @resource, @version )

        # ...noting that @remote_info may now contain either a URI for local
        # development / real HTTP environments, or a Hash with ":queue" and
        # ":path" values - see the middleware's #remote_service_for.

      end

      # Obtain a list of resource instance representations.
      #
      # +query_hash+:: See #initialize. This is the only way to search/filter
      #                the list, according to the targer Resource's documented
      #                supported search/filter parameters and the platform's
      #                common all-resource behaviour.
      #
      # Returns an ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedArray
      # representation of the requested list of resource instances. Call
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedArray#adds_errors_to?
      # or
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedArray#platform_errors
      # on the returned instance to detect and resolve error conditions _before_
      # examining its Array-derived contents. The contents will be empty in
      # non-error cases if no items satisfying the list conditions were found.
      #
      def list( query_hash = nil )
        return @middleware.inter_resource(
          :local       => @local_service,
          :remote      => @remote_info,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'GET',
          :query_hash  => query_hash
        )
      end

      # Obtain a resource instance representation.
      #
      # +ident+::      See #initialize.
      # +query_hash+:: See #initialize.
      #
      # Returns an ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash
      # representation of the requested resource instance. Call
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#adds_errors_to?
      # or
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#platform_errors
      # on the returned instance to detect and resolve error conditions _before_
      # examining its Hash-derived fields.
      #
      def show( ident, query_hash = nil )
        return @middleware.inter_resource(
          :local       => @local_service,
          :remote      => @remote_info,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'GET',
          :ident       => ident,
          :query_hash  => query_hash
        )
      end

      # Create a resource instance.
      #
      # +body_hash+::  See #initialize.
      # +query_hash+:: See #initialize.
      #
      # Returns an ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash
      # representation of the new resource instance. Call
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#adds_errors_to?
      # or
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#platform_errors
      # on the returned instance to detect and resolve error conditions _before_
      # examining its Hash-derived fields.
      #
      def create( body_hash, query_hash = nil )
        return @middleware.inter_resource(
          :local       => @local_service,
          :remote      => @remote_info,
          :resource    => @resource,
          :version     => @version,

          :http_method => 'POST',
          :body_hash   => body_hash,
          :query_hash  => query_hash
        )
      end

      # Update a resource instance.
      #
      # +ident+::      See #initialize.
      # +body_hash+::  See #initialize.
      # +query_hash+:: See #initialize.
      #
      # Returns an ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash
      # representation of the updated resource instance. Call
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#adds_errors_to?
      # or
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#platform_errors
      # on the returned instance to detect and resolve error conditions _before_
      # examining its Hash-derived fields.
      #
      def update( ident, body_hash, query_hash = nil )
        return @middleware.inter_resource(
          :local       => @local_service,
          :remote      => @remote_info,
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
      # +ident+::      See #initialize.
      # +query_hash+:: See #initialize.
      #
      # Returns an ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash
      # representation of the now-deleted resource instance. Call
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#adds_errors_to?
      # or
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash#platform_errors
      # on the returned instance to detect and resolve error conditions _before_
      # examining its Hash-derived fields.
      #
      def delete( ident, query_hash = nil )
        return @middleware.inter_resource(
          :local       => @local_service,
          :remote      => @remote_info,
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
