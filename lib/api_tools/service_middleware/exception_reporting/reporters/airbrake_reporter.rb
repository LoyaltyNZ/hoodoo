########################################################################
# File::    airbrake_reporter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Connect the middleware to Airbrake.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class ServiceMiddleware
    class ExceptionReporting

      # ApiTools::ServiceMiddleware::ExceptionReporting::Base subclass giving
      # ApiTools::ServiceMiddleware::ExceptionReporting access to Airbrake for
      # error reporting. See https://airbrake.io.
      #
      # Your application must include the Airbrake gem 'airbrake' via Gemfile
      # (+gem 'airbrake'+ / +bundle install) or direct installation (+gem
      # install airbrake+).
      #
      # The API key must be set during your application initialization and the
      # class must be added to ApiTools for use as an error reporter, e.g.
      # through a 'config/initializers' folder, as follows:
      #
      #     require 'airbrake'
      #
      #     Airbrake.configure do | config |
      #       config.api_key = 'YOUR_AIRBRAKE_API_KEY'
      #     end
      #
      #     ApiTools::ServiceMiddleware::ExceptionReporting.add(
      #       ApiTools::ServiceMiddleware::ExceptionReporting::AirbrakeReporter
      #     )
      #
      # Services and the ApiTools middleware do not pass Rails-like params
      # around in forms or query strings, but do beware of search or filter
      # query data containing sensitive material or POST bodies in e.g. JSON
      # encoding containing sensitive data. This comes down to the filtering
      # ability of the Airbrake gem:
      #
      #   https://github.com/airbrake/airbrake/wiki/Customizing-your-airbrake.rb
      #
      class AirbrakeReporter < ApiTools::ServiceMiddleware::ExceptionReporting::Base

        # Report an exception to Airbrake.
        #
        # +e+::   Exception (or subclass) instance to be reported.
        #
        # +env+:: Optional Rack environment hash for the inbound request, for
        #         exception reports made in the context of Rack request
        #         handling.
        #
        def report( e, env = {} )
          Airbrake.notify_or_ignore( e, :parameters => env )
        end
      end

    end
  end
end
