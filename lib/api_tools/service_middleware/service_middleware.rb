module ApiTools

  # A container for the Rack-based service middleware.
  #
  class ServiceMiddleware

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )
      @app = app

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

      processor = ApiTools::ServiceMiddleware::Processor.new( preprocessor )
      response = processor.process( @app )

      postprocessor = ApiTools::ServiceMiddleware::Postprocessor.new( response )
      return postprocesor.postprocess()
    end
  end
end
