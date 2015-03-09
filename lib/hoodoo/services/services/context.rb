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
        @endpoints          = {}
      end

      # Request (and lazy-initialize) a new resource endpoint instance for
      # talking to a resource's interface. See
      # Hoodoo::Services::Middleware::Endpoint.
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
      def resource( resource, version = 1 )
        @endpoints[ "#{ resource }/#{ version }" ] ||= self.endpoint_for( resource, version )
      end

    private

      # Back-end for #resource which asks the owning middleware to give an
      # inter-resource (local or remote) endpoint.
      #
      # +resource+:: Resource name for the endpoint, String or Symbol.
      # +version+::  Required implemented version for the endpoint, Integer.
      #
      def endpoint_for( resource, version )
        middleware = @self.owning_interaction.owning_middleware_instance

        return middleware.inter_resource_endpoint_for(
          resource,
          version,
          self.owning_interaction
        )
      end

  end
end; end
