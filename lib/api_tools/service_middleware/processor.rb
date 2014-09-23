module ApiTools
  class ServiceMiddleware

    # Common processing actions for client calls. This is the core of the
    # service middleware, calling into Rack apps NOT via the traditional Rack
    # interface of "+call(env)}+" but instead by a high level interface that
    # has aspects of Rails, Sinatra and other Rack frameworks in its design.
    #
    # Construct, call #process and use the updated object to construct
    # an ApiTools::ServiceMiddleware::PostProcessor instance.
    #
    class Processor

      # Initialize an instance so that it can do useful work.
      #
      # +preprocessor+ ApiTools::ServiceMiddleware::PreProcessor instance where
      #                ApiTools::ServiceMiddleware::PreProcessor#preprocess has
      #                already been called.
      #
      def initialize( preprocessor )
      end

      # Process the client's call in the context of the preprocessed data
      # provided in #initialize, for the given Rack application. Once done,
      # internal data will be ready for use by an
      # ApiTools::ServiceMiddleware::PostProcessor instance.
      #
      # +svc+ An ApiTools::ServiceApplication subclass instance, which is
      #       probably something instantiated by Rack via Rack's "run()"
      #       method and passed to the middleware by Rack itself, though not
      #       necessarily.
      #
      def process( svc )

        So we ask SVC for its list of components

      end
    end

  end
end
