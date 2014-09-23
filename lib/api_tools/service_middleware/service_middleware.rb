module ApiTools

  # A container for the Rack-based service middleware.
  #
  class ServiceMiddleware

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )
      @service = app

      unless @service.is_a?( ApiTools::ServiceApplication )
        raise "ApiTools::ServiceMiddleware instance created with non-ServiceApplication entity of class '#{ @service.class }' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?"
      end

      @service.component_interfaces.each do | interface |
      end

      #   # e.g. version = "v1", endpoint - 'purchases'
      #   endpoints.each do | endpoint |
      #     map( "/#{ version }" ) do
      #       map( "/#{ endpoint }" ) do
      #         run <something>
      #       end
      #     end
      #   end
    end

    # Run a Rack request, returning the [status, headers, body-array]
    # data as per the Rack protocol requirements.
    #
    # +env+ Rack environment.
    #
    def call( env )
      preprocessor = ApiTools::ServiceMiddleware::Preprocessor.new( env )
      preprocessor.preprocess()

      response = process( @service )

      postprocessor = ApiTools::ServiceMiddleware::Postprocessor.new( response )
      return postprocesor.postprocess()
    end

  private

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    def process
    end
  end
end
