module Hoodoo; module Services; class Middleware
  class Interaction

    public

      attr_reader :owning_middleware_instance

      attr_reader :rack_request
      attr_reader :interaction_id
      attr_accessor :context

      attr_accessor :target_interface
      attr_accessor :target_resource_for_error_reports
      attr_accessor :target_implementation

      attr_accessor :requested_action
      attr_accessor :requested_content_type
      attr_accessor :requested_content_encoding

      def initialize( env, owning_middleware_instance )
        @rack_request   = Rack::Request.new( env )
        @interaction_id = find_or_generate_interaction_id()
        @context        = Hoodoo::Services::Context.new(
          nil,
          Hoodoo::Services::Request.new,
          Hoodoo::Services::Response.new( @interaction_id ),
          self
        )

        @owning_middleware_instance = owning_middleware_instance
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
