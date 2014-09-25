module ApiTools
  class ServiceMiddleware

    # Common pre-processing actions for all client calls. Makes sure the
    # requests look well formatted, adds the Interaction ID if it is absent
    # and so-on.
    #
    # Construct, call #preprocess and use the updated object to construct an
    # ApiTools::ServiceMiddleware::Processor instance.
    #
    class Preprocessor

      attr_reader( :locale, :interaction_id, :payload_hash )

      # Initialize with a Rack environment hash.
      #
      # +env+ Rack environment.
      #
      def initialize( for_request, using_response )
        @request  = for_request
        @response = using_response
      end

      # Run preprocessing actions. Once done, internal data will be ready for
      # use by an ApiTools::ServiceMiddleware::Processor instance.
      #
      def preprocess
        check_content_type_header()

        @locale         = deal_with_language_header()
        @interaction_id = find_or_generate_interaction_id()
        @payload_hash   = json_to_hash()

        @errors = ApiTools::Errors.new()

        return @request
      end


    private

      #

      def check_content_type_header()
      end
    end

  end
end
