module ApiTools
  class ServiceMiddleware

    # Common post-processing actions for all client calls.
    #
    # Construct, call #postprocess and return the returned result directly to
    # Rack via your implementation of this Rack middleware's +call+ method.
    #
    class Postprocessor

      # Initialize an instance so that it can do useful work.
      #
      # +processor+ ApiTools::ServiceMiddleware::Processor instance where
      #             ApiTools::ServiceMiddleware::Processor#process has
      #             been called.
      #
      def initialize( processor )
        @processor = processor
      end

      # Modify response data using common alterations, returning a result
      # in a Rack-compatible response format of [ HTTP code, HTTP headers,
      # body in an object which responds to "each" ].
      #
      def postprocess()
      end
    end

  end
end
