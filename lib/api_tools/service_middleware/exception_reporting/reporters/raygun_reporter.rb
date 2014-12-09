########################################################################
# File::    raygun_reporter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Connect the middleware to Raygun.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class ServiceMiddleware
    class ExceptionReporting

      # ApiTools::ServiceMiddleware::ExceptionReporting::Base subclass giving
      # ApiTools::ServiceMiddleware::ExceptionReporting access to Raygun for
      # error reporting. See https://raygun.io.
      #
      # Your application must include the Raygun gem 'raygun4ruby' via Gemfile
      # (+gem 'raygun4ruby'+ / +bundle install) or direct installation (+gem
      # install raygun4ruby+).
      #
      # The API key must be set during your application initialization and the
      # class must be added to ApiTools for use as an error reporter, e.g.
      # through a 'config/initializers' folder, as follows:
      #
      #     require 'raygun4ruby'
      #
      #     Raygun.setup do | config |
      #       config.api_key = 'YOUR_RAYGUN_API_KEY'
      #     end
      #
      #     ApiTools::ServiceMiddleware::ExceptionReporting.add(
      #       ApiTools::ServiceMiddleware::ExceptionReporting::RaygunReporter
      #     )
      #
      # Services and the ApiTools middleware do not pass Rails-like params
      # around in forms or query strings, but do beware of search or filter
      # query data containing sensitive material or POST bodies in e.g. JSON
      # encoding containing sensitive data. This comes down to the filtering
      # ability of the Raygun gem:
      #
      #   https://github.com/MindscapeHQ/raygun4ruby
      #
      class RaygunReporter < ApiTools::ServiceMiddleware::ExceptionReporting::Base

        # Report an exception to Raygun.
        #
        # +e+::   Exception (or subclass) instance to be reported.
        #
        # +env+:: Optional Rack environment hash for the inbound request, for
        #         exception reports made in the context of Rack request
        #         handling.
        #
        def report( e, env = {} )
          Raygun.track_exception( e, :rack_env => env )
        end
      end

    end
  end
end
