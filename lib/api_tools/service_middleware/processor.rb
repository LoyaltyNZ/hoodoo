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
      # +app+ A Rack application instance - but in this case, it must be any
      #       object instance that conforms to the service interface we define,
      #       rather than something expecting "+call(env)}+".
      #
      def process( app )
        unless app.is_a?( ApiTools::BaseService )
          raise "ApiTools::ServiceMiddleware must be at the end of Rack's 'use' chain of middleware and expects to be run with an ApiTools::BaseService subclass as the Rack application."
        end

      end
    end

  end
end
