########################################################################
# File::    endpoint.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  class Client # Just used as a namespace here

    # Base class for endpoint code.
    #
    # This base class defines the API to which subclasses must adhere,
    # so that endpoint users don't need to care how the endpoint
    # actually communicates with a target resource.
    #
    # ENDPOINTS ARE NOT INTENDED TO BE THREAD SAFE. Whenever you want to
    # use one from a particular thread, instantiate an endpoint for use by
    # just that thread. Don't share instances between threads via e.g.
    # controlling class instance variables recording a reference to a
    # single endpoint object.
    #
    class Endpoint

      # Endpoint factory - instantiates and endpoint for the given resource
      # and implemented API version, using the given discoverer.
      #
      # +resource+:: Resource name the endpoint targets, e.g. +:Purchase+.
      #              String or symbol.
      #
      # +version+::  Optional required interface (API) version for that
      #              endpoint. Integer. Default is 1.
      #
      # +options+::  Options Hash. Options are described below. Note that
      #              this Hash may be modified during processing.
      #
      # Items in the options hash are required, unless explicitly listed
      # as optional. They are:
      #
      # +discoverer+::     A Hoodoo::Services::Discovery "By..." family
      #                    member instance, e.g. a
      #                    Hoodoo::Services::Discovery::ByDRb instance.
      #                    This is used to look up a service instance. The
      #                    returned discovery data type is used to determine
      #                    the required endpoint type; for example, a
      #                    Hoodoo::Services::Discovery::ForHTTP result yields
      #                    a Hoodoo::Client::Endpoint::HTTP instance.
      #
      # +session_id+::     A session UUID, for the X-Session-ID HTTP header
      #                    or an equivalent. Optional, but if omitted, only
      #                    public resource actions will be accessible.
      #
      # +locale+::         Locale string for request/response, e.g. "en-gb".
      #                    Optional. If omitted, defaults to "en-nz".
      #
      # +dated_at+::       Time instance, DateTime instance or String which
      #                    Ruby can parse into a DateTime instance used for
      #                    show/list calls to resource endpoints that support
      #                    historical representation, via an X-Dated-At HTTP
      #                    header or equivalent. If omitted, defaults to +nil+
      #                    (no historical representation requested).
      #
      # +interaction+::    A Hoodoo::Services::Middleware::Interaction
      #                    instance which describes a *source* interaction at
      #                    hand. This is a middleware concept and most of the
      #                    time, only the middleware would use this; the
      #                    middleware is handling some API call which the
      #                    source interaction data describes but the resource
      #                    which is handling the call needs to make an
      #                    inter-resource call, which is why an Endpoint is
      #                    being created.
      #
      # Returns a Hoodoo::Services::Discovery "For..." family member
      # instance (e.g. Hoodoo::Services::Discovery::ForHTTP) which can be
      # used to talk to the resource in question. Getting an instance does
      # not mean the resource endpoint is found - you will not know that
      # until you try to talk to it and get a 404 expressed as a platform
      # error in the response data. See Hoodoo::Client::AugmentedHash and
      # Hoodoo::Client::AugmentedArray.
      #
      # Callers dealing with inter-resource call code may want to consult
      # their discoverer to see if the resource is locally available
      # before bothering to instantiate an endpoint.
      #
      def self.endpoint_for( resource, version, options )
        discoverer       = options.delete( :discoverer )
        discovery_result = discoverer.discover( resource.to_sym, version.to_i )

        klass = if discovery_result.is_a?( Hoodoo::Services::Discovery::ForHTTP )
          Hoodoo::Client::Endpoint::HTTP
        elsif discovery_result.is_a?( Hoodoo::Services::Discovery::ForAMQP )
          Hoodoo::Client::Endpoint::AMQP
        elsif discovery_result.nil?
          Hoodoo::Client::Endpoint::NotFound
        else
          nil
        end

        options[ :discovery_result ] = discovery_result

        if klass.nil?
          raise "Hoodoo::Client::Endpoint::endpoint_for: Unrecognised discoverer result class of '#{ discovery_result.class.name }'"
        else
          return klass.new( resource, version, options )
        end
      end

      # The resource name passed to the constructor, as a String.
      #
      attr_reader :resource

      # The version number passed to the constructor, as an Integer.
      #
      attr_reader :version

      # The value of the +interaction+ option key passed to the
      # constructor. See the constructor and #endpoint_for for more.
      #
      attr_reader :interaction

      # The locale passed to the constructor or some value provided later; a
      # String, e.g. "en-gb", or if +nil+, uses "en-nz" by default.
      #
      attr_accessor :locale

      # The session UUID passed to the constructor or some value provided
      # later; used for the calls to the target resource via the X-Session-ID
      # HTTP header or an equivalent. If +nil+, only public actions in the
      # target resource will be accessible.
      #
      attr_accessor :session_id

      # The locale passed to the constructor or some value provided later; a
      # String, e.g. "en-gb", or if +nil+, uses "en-nz" by default.
      #
      attr_accessor :locale

      # A DateTime instance equivalent to the ISO 8601 representation given
      # in the X-Dated-At HTTP header or equivalent, used for calls to show
      # or list resources that support historical representation. If +nil+,
      # the instantaneous internal endpoint target processing time of
      # 'now' is implied.
      #
      attr_accessor :dated_at

      # Create an endpoint instance that will be used to make requests to
      # a given resource.
      #
      # +resource+:: Resource name the endpoint targets, e.g. +:Purchase+.
      #              String or symbol.
      #
      # +version+::  Optional required interface (API) version for that
      #              endpoint. Integer. Default is 1.
      #
      # +options+::  Options Hash. Options are described below. Note that
      #              this Hash may be modified during processing.
      #
      # Items in the options hash are required, unless explicitly listed
      # as optional. They are:
      #
      # +discovery_result+:: A Hoodoo::Services::Discovery "For..." family
      #                      member instance, e.g. a
      #                      Hoodoo::Services::Discovery::ForHTTP instance.
      #                      Each subclass describes its required discovery
      #                      result type, so see its documentation for
      #                      details.
      #
      # +interaction+::      As in the options for #endpoint_for.
      #
      # +session_id+::       As in the options for #endpoint_for.
      #
      # +locale+::           As in the options for #endpoint_for.
      #
      # +dated_at+::         As in the options for #endpoint_for.
      #
      # The out-of-the box initialiser sets up the data for the #resource,
      # #version, #discovery_result, #interaction, #session_id, #locale and
      # #dated_at accessors using this data, so subclass authors don't need
      # to.
      #
      # The endpoint is then used with #list, #show, #create, #update or
      # #delete methods to perform operations on the target resource. See
      # each of those methods for details of their specific requirements;
      # however all have common parameters some or all of which are used
      # across the method 'family':
      #
      # +ident+::      Identifier. This is usually a UUID but some Resources
      #                support e.g. a "show" action based on either a UUID
      #                or some other unique value (such as a product code,
      #                a credit/debit card number or so-on - defined by the
      #                Resource in question in its documentation).
      #
      # +query_hash+:: A hash of _unencoded_ data that can be encoded to form
      #                a query string. Search and filter data is represented
      #                with nested hashes. Embed and reference data uses an
      #                array. Example:
      #
      #                   {
      #                     offset:    75,
      #                     limit:     50,
      #                     sort:      'created_at', # ...or an Array of sort fields
      #                     direction: 'asc',        # ...or a matching Array of directions
      #                     search:    {
      #                       member_id: "...some UUID..."
      #                     },
      #                     _embed:    [
      #                       'vouchers',
      #                       'balances'
      #                     ],
      #                     # and/or ...filter: {}..., _reference: []...
      #                   }
      #
      #                This parameter is always optional.
      #
      # +body_hash+::  The Hash representation of the body data that might be
      #                sent in an HTTP request (i.e. JSON, as a Hash).
      #
      def initialize( resource, version = 1, options )
        @resource         = resource.to_sym
        @version          = version.to_i
        @dated_at         = Hoodoo::Utilities.rationalise_datetime( options[ :dated_at ] )
        @discovery_result = options[ :discovery_result ]
        @session_id       = options[ :session_id       ]
        @locale           = options[ :locale           ]
        @interaction      = options[ :interaction      ]

        configure_with( @resource, @version, options )
      end

      ########################################################################
      # And then subclass authors implement...
      ########################################################################

      protected

        # This protected method is implemented by subclasses and called from
        # the initializer. Subclasses should store resource and version data
        # however they want and validate any required options, raising errors
        # if need be.
        #
        # +resource+:: Resource name the endpoint targets, e.g. +:Purchase+.
        #              Symbol.
        #
        # +version+::  Optional required interface (API) version for that
        #              endpoint. Integer.
        #
        # +options+::  Options Hash. Same as for #initialize.
        #
        def configure_with( resource, version, options )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#configure_with"
        end

        # Utility method to aid subclass authors. Not usually overridden.
        #
        # Determine the response class needed for a given action - returns
        # Hoodoo::Client::AugmentedArray or Hoodoo::Client::AugmentedHash
        # (class references, not instances).
        #
        # +action+:: A Symbol from
        #            Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
        #
        def response_class_for( action )
          return action === :list ? Hoodoo::Client::AugmentedArray : Hoodoo::Client::AugmentedHash
        end

        # Utility method to aid subclass authors. Not usually overridden.
        #
        # Return an instance of Hoodoo::Client::AugmentedArray or
        # Hoodoo::Client::AugmentedHash with an associated 404 error (as
        # a fully formed platform error) describing 'Not Found' for the
        # target resource, version and given action.
        #
        # +action+:: A Symbol from
        #            Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
        #
        def generate_404_response_for( action )
          data = response_class_for( action ).new
          data.platform_errors.add_error(
            'platform.not_found',
            'reference' => { :entity_name => "v#{ @version } of #{ @resource } interface endpoint" }
          )

          return data
        end

      public

        # Obtain a list of resource instance representations.
        #
        # +query_hash+:: See the constructor for more. This is the only way
        #                to search or filter the list, via the target
        #                Resource's documented supported search/filter
        #                parameters and the platform's common all-Resources
        #                behaviour.
        #
        # Returns a Hoodoo::Client::AugmentedArray representation of the
        # requested list of resource instances.
        #
        # Call Hoodoo::Client::AugmentedArray#platform_errors (or for
        # service authors implementing resource endpoints, possibly call
        # Hoodoo::Client::AugmentedArray#adds_errors_to? instead) on the
        # returned instance to detect and resolve error conditions _before_
        # examining its Array-derived contents.
        #
        # The array will be empty in successful responses if no items
        # satisfying the list conditions were found. The array contents
        # are undefined in the case of errors.
        #
        def list( query_hash = nil )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#list"
        end

        # Obtain a resource instance representation.
        #
        # +ident+::      See the constructor for details.
        # +query_hash+:: See the constructor for details.
        #
        # Returns a Hoodoo::Client::AugmentedHash representation of the
        # requested resource instance.
        #
        # Call Hoodoo::Client::AugmentedHash#platform_errors (or for
        # service authors implementing resource endpoints, possibly call
        # Hoodoo::Client::AugmentedHash#adds_errors_to? instead)
        # on the returned instance to detect and resolve error conditions
        # _before_ examining its Hash-derived fields.
        #
        # The hash contents are undefined when errors are returned.
        #
        def show( ident, query_hash = nil )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#show"
        end

        # Create a resource instance.
        #
        # +body_hash+::  See the constructor for details.
        # +query_hash+:: See the constructor for details.
        #
        # Returns a Hoodoo::Client::AugmentedHash representation of the
        # new resource instance.
        #
        # Call Hoodoo::Client::AugmentedHash#platform_errors (or for
        # service authors implementing resource endpoints, possibly call
        # Hoodoo::Client::AugmentedHash#adds_errors_to? instead)
        # on the returned instance to detect and resolve error conditions
        # _before_ examining its Hash-derived fields.
        #
        # The hash contents are undefined when errors are returned.
        #
        def create( body_hash, query_hash = nil )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#create"
        end

        # Update a resource instance.
        #
        # +ident+::      See the constructor for details.
        # +body_hash+::  See the constructor for details.
        # +query_hash+:: See the constructor for details.
        #
        # Returns a Hoodoo::Client::AugmentedHash representation of the
        # updated resource instance.
        #
        # Call Hoodoo::Client::AugmentedHash#platform_errors (or for
        # service authors implementing resource endpoints, possibly call
        # Hoodoo::Client::AugmentedHash#adds_errors_to? instead)
        # on the returned instance to detect and resolve error conditions
        # _before_ examining its Hash-derived fields.
        #
        # The hash contents are undefined when errors are returned.
        #
        def update( ident, body_hash, query_hash = nil )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#update"
        end

        # Delete a resource instance.
        #
        # +ident+::      See the constructor for details.
        # +query_hash+:: See the constructor for details.
        #
        # Returns a Hoodoo::Client::AugmentedHash representation of the
        # now-deleted resource instance,from the instant before deletion.
        #
        # Call Hoodoo::Client::AugmentedHash#platform_errors (or for
        # service authors implementing resource endpoints, possibly call
        # Hoodoo::Client::AugmentedHash#adds_errors_to? instead)
        # on the returned instance to detect and resolve error conditions
        # _before_ examining its Hash-derived fields.
        #
        # The hash contents are undefined when errors are returned.
        #
        def delete( ident, query_hash = nil )
          raise "Subclasses must implement Hoodoo::Client::Endpoint\#delete"
        end

    end
  end
end