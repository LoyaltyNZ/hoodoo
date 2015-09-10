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
      # +locale+:: Locale string for request/response, e.g. "en-gb". Optional.
      #            If omitted, defaults to the locale set in this Client
      #            instance's constructor.
      #
      # Others::   See Hoodoo::Client::Endpoint's HEADER_TO_PROPERTY.
      #            For any options in that map which describe themselves as
      #            being automatically transferred from one endpoint to
      #            another, you can prevent this by explicitly pasisng a
      #            +nil+ value for the option; otherwise, _OMIT_ the option
      #            for normal behaviour. Non-auto-transfer properties can be
      #            specified as +nil+ or omitted with no change in behaviour.
      #
      def resource( resource, version = 1, options = {} )
        middleware = @owning_interaction.owning_middleware_instance
        endpoint   = middleware.inter_resource_endpoint_for(
          resource,
          version,
          @owning_interaction
        )

        endpoint.locale = options[ :locale ] unless options[ :locale ].nil?

        Hoodoo::Client::Endpoint::HEADER_TO_PROPERTY.each do | rack_header, description |
          property      = description[ :property      ]
          auto_transfer = description[ :auto_transfer ]

          # For automatically transferred options there's no way to stop the
          # auto transfer unless explicitly stating 'nil' to overwrite any
          # existing value, so here, only write the value into the endpoint if
          # the property specifically exists in the inbound options hash.
          #
          # For other properties, 'nil' has no meaning and there's no need to
          # override anything, so use "unless nil?" in that case.

          setter = "#{ property }="
          value  = options[ property ]

          if auto_transfer == true
            endpoint.send( setter, value ) if options.has_key?( property )
          else
            endpoint.send( setter, value ) unless value.nil?
          end
        end

        return endpoint
      end

  end
end; end
