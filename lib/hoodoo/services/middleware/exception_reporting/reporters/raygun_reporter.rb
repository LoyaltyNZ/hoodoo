########################################################################
# File::    raygun_reporter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Send exception details to Raygun.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services
  class Middleware

    class ExceptionReporting

      # Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter subclass
      # giving Hoodoo::Services::Middleware::ExceptionReporting access to
      # Raygun for error reporting. See https://raygun.io.
      #
      # Your application must include the Raygun gem 'raygun4ruby' via Gemfile
      # (+gem 'raygun4ruby'+ / +bundle install) or direct installation (+gem
      # install raygun4ruby+).
      #
      # The API key must be set during your application initialization and the
      # class must be added to Hoodoo for use as an error reporter, e.g.
      # through a 'config/initializers' folder, as follows:
      #
      #     require 'raygun4ruby'
      #
      #     Raygun.setup do | config |
      #       config.api_key = 'YOUR_RAYGUN_API_KEY'
      #     end
      #
      #     Hoodoo::Services::Middleware::ExceptionReporting.add(
      #       Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter
      #     )
      #
      # Services and the Hoodoo middleware do not pass Rails-like params
      # around in forms or query strings, but do beware of search or filter
      # query data containing sensitive material or POST bodies in e.g. JSON
      # encoding containing sensitive data. This comes down to the filtering
      # ability of the Raygun gem:
      #
      #   https://github.com/MindscapeHQ/raygun4ruby
      #
      class RaygunReporter < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter

        # Report an exception to Raygun.
        #
        # +e+::   Exception (or subclass) instance to be reported.
        #
        # +env+:: Optional Rack environment hash for the inbound request, for
        #         exception reports made in the context of Rack request
        #         handling.
        #
        def report( e, env = nil )
          Raygun.track_exception( e, env )
        end
      end

    end

  end
end; end
