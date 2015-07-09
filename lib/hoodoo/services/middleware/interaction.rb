########################################################################
# File::    interaction.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Encapsulate all data related to an interaction (API call)
#           inside an object.
# ----------------------------------------------------------------------
#           13-Feb-2015 (ADH): Created.
########################################################################

module Hoodoo; module Services; class Middleware

  # Encapsulate all data related to an interaction (API call) within
  # one object.
  #
  class Interaction

    public

      # API calls are handled by the middleware, so Interactions are
      # created by Hoodoo::Services::Middleware instances. This is that
      # creating instance, or the instance that should be treated as if
      # it were the creator.
      #
      attr_reader :owning_middleware_instance

      # The inbound Rack request a Rack::Request instance.
      #
      attr_reader :rack_request

      # Every interaction has a UUID passed back in API responses via
      # the X-Interaction-ID HTTP header. This is that UUID.
      #
      attr_reader :interaction_id

      # A Hoodoo::Services::Context instance representing this API call.
      # May be updated/replaced during processing.
      #
      attr_accessor :context

      # The Hoodoo::Services::Interface subclass describing the resource
      # interface that is the target of the API call.
      #
      attr_accessor :target_interface

      # The target Hoodoo::Services::Implementation instance for the
      # API call. See #target_interface.
      #
      attr_accessor :target_implementation

      # The requested action, as a symbol; see
      # Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
      #
      attr_accessor :requested_action

      # The requested content type as a String - e.g. "application/json".
      #
      attr_accessor :requested_content_type

      # The requested content encoding as a String - e.g. "utf-8".
      #
      attr_accessor :requested_content_encoding

      # Hoodoo middleware calls here to say "I'm using the test session" (or
      # not), so that this can be enquired about via #using_test_session? if
      # need be.
      #
      def using_test_session
        @using_test_session = true
      end

      # Returns +true+ if Hoodoo has previously called #using_test_session.
      #
      def using_test_session?
        @using_test_session === true
      end

      # Create a new Interaction instance, acquiring a new interaction
      # ID automatically or picking up one from an X-Interaction-ID
      # header if available.
      #
      # A new context instance (see #context) is generated with a new
      # empty request and response object attached, along with +nil+
      # session data or the given session information in the input
      # parameters:
      #
      # +env+:: The raw Rack request Hash. May be "{}" in some test
      #         scenarios. Converted to a Rack::Request instance. If
      #         this describes an X-Interaction-ID header then this
      #         Interaction will use - without validation - whatever
      #         value the header holds, else a new UUID is generated.
      #
      # +owning_middleware_instance+:: See #owning_middleware_instance.
      #
      # +session+:: The session data attached to the #context value;
      #             optional; if omitted, +nil+ is used.
      #
      def initialize( env, owning_middleware_instance, session = nil )
        @rack_request   = ::Rack::Request.new( env )
        @interaction_id = find_or_generate_interaction_id()
        @context        = Hoodoo::Services::Context.new(
          session,
          Hoodoo::Services::Request.new,
          Hoodoo::Services::Response.new( @interaction_id ),
          self
        )

        @owning_middleware_instance = owning_middleware_instance
        @context.request.headers    = env.select() do | k,v |
          k.to_s.start_with?( 'HTTP_' ) || k == 'CONTENT_TYPE' || k == 'CONTENT_LENGTH'
        end.freeze()
      end

    private

      # Find the value of an X-Interaction-ID header (if one is already present)
      # or generate a new Interaction ID.
      #
      def find_or_generate_interaction_id
        iid = self.rack_request.env[ 'HTTP_X_INTERACTION_ID' ]
        iid = Hoodoo::UUID.generate() if iid.nil? || iid == ''
        iid
      end

  end

end; end; end
