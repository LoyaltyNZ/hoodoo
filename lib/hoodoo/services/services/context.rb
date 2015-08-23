########################################################################
# File::    context.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Container for information about the context of a call to
#           a service, including session, request and response.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services

  # A collection of objects which describe the context in which a service is
  # being called. The service reads session and request information and returns
  # results of its processing via the associated response object.
  #
  class Context

    public

      # The Hoodoo::Services::Session instance describing the authorised call
      # context. If a resource implementation is handling a public action this
      # may be +nil+, else it will be a valid instance.
      #
      attr_reader :session

      # The Hoodoo::Services::Request instance giving details about the
      # inbound request. Relevant information will depend upon the endpoint
      # service implementation action being addressed.
      #
      attr_reader :request

      # The Hoodoo::Services::Response instance that a service implementation
      # updates with results of its processing.
      #
      attr_reader :response

      # The Hoodoo::Services::Middleware::Interaction instance for which this
      # context exists (the 'owning' instance). Generally speaking this is
      # only needed internally as part of the inter-resource call mechanism.
      #
      attr_reader :owning_interaction

      # Create a new instance. There is almost certainly never any need to
      # call this unless you're the Hoodoo::Services::Middleware::Interaction
      # constructor! If you want to build a context for (say) test purposes,
      # it's probably best to construct an interaction instance and use the
      # context instance this provides.
      #
      # +session+:: See #session.
      # +request+:: See #request.
      # +response+:: See #response.
      # +owning_interaction+:: See #interaction.
      #
      def initialize( session, request, response, owning_interaction )
        @session            = session
        @request            = request
        @response           = response
        @owning_interaction = owning_interaction
      end

      # Request (and lazy-initialize) a new resource endpoint instance for
      # talking to a resource's interface. See Hoodoo::Client::Endpoint.
      #
      # You can request an endpoint for any resource name, whether or not an
      # implementation actually exists for it. Until you try and talk to the
      # interface through the endpoint instance, you won't know if it is
      # there. All endpoint methods return instances of classes that mix in
      # Hoodoo::Client::AugmentedBase; these
      # mixin methods provide error handling options to detect a "not found"
      # error (equivanent to HTTP status code 404) returned when a resource
      # implementation turns out to not actually be present.
      #
      # The idiomatic call sequence is something like the following, where
      # you get hold of an endpoint, make a call and handle the response:
      #
      #     clock = context.resource( :Clock, 2 ) # v2 of 'Clock' resource
      #     time  = clock.show( 'now' )
      #
      #     return if time.adds_errors_to?( context.response.errors )
      #
      # ...or alternatively:
      #
      #     clock = context.resource( :Clock, 2 ) # v2 of 'Clock' resource
      #     time  = clock.show( 'now' )
      #
      #     context.response.add_errors( time.platform_errors )
      #     return if context.response.halt_processing?
      #
      # The return value of calls made to the endpoint is an Array or Hash
      # that mixes in Hoodoo::Client::AugmentedBase;
      # see this class's documentation for details of the two alternative
      # error handling approaches shown above.
      #
      # +resource+:: Resource name for the endpoint, e.g. +:Purchase+. String
      #              or symbol.
      #
      # +version+::  Optional required implemented version for the endpoint,
      #              as an Integer - defaults to 1.
      #
      # +options+::  Optional options Hash (see below).
      #
      # The options Hash key/values are as follows:
      #
      # +locale+::     Locale string for request/response, e.g. "en-gb".
      #                Optional. If omitted, defaults to the locale set in this
      #                Client instance's constructor.
      #
      # +dated_at+::   Time instance, DateTime instance or String which Ruby
      #                can parse into a DateTime instance used for show/list
      #                calls to resource endpoints that support historical
      #                representation, via an <tt>X-Dated-At</tt> HTTP header
      #                or equivalent. If omitted, acquires whatever "dated_at"
      #                value exists in the current request - historic dating
      #                requests propagate automatically from one endpoint to
      #                another. If you wish to explicitly override this, you
      #                _MUST_ include the option key with an explicit value of
      #                 +nil+.
      #
      # +dated_from+:: Time instance, DateTime instance or String that Ruby
      #                can parse into a DateTime instance used for creation
      #                calls to resource endpoints that support creation time
      #                specification via an <tt>X-Dated-From</tt> HTTP header
      #                or equivalent, as part of their support for historical
      #                representation via a <tt>X-Dated-At</tt> HTTP header or
      #                equivalent. If omitted, defaults to the created resource
      #                being created at and thus valid from the server's value
      #                of "now"; unlike "dated_at", this property does not
      #                automatically propagage from one endpoint to another.
      #
      def resource( resource, version = 1, options = {} )
        middleware = @owning_interaction.owning_middleware_instance
        endpoint   = middleware.inter_resource_endpoint_for(
          resource,
          version,
          @owning_interaction
        )

        locale     = options[ :locale     ]
        dated_at   = options[ :dated_at   ]
        dated_from = options[ :dated_from ]

        # 'unless' for things where 'nil' makes no sense or no value is set
        # by default, so overriding is unnecessray; key presence check for
        # things where 'nil' has a meaning and non-nil values may require
        # overriding.

        endpoint.locale     = locale     unless locale.nil?
        endpoint.dated_from = dated_from unless dated_from.nil?
        endpoint.dated_at   = dated_at   if options.has_key?( :dated_at )

        return endpoint
      end

  end
end; end
