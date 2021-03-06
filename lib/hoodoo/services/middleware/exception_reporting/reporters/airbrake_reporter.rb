########################################################################
# File::    airbrake_reporter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Send exception details to Airbrake.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services
  class Middleware

    class ExceptionReporting

      # Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter subclass
      # giving Hoodoo::Services::Middleware::ExceptionReporting access to
      # Airbrake for error reporting. See https://airbrake.io.
      #
      # Your application must include the Airbrake gem 'airbrake' via Gemfile
      # (+gem 'airbrake'+ / +bundle install) or direct installation (+gem
      # install airbrake+).
      #
      # The API key must be set during your application initialization and the
      # class must be added to Hoodoo for use as an error reporter, e.g.
      # through a 'config/initializers' folder, as follows:
      #
      #     require 'airbrake'
      #
      #     Airbrake.configure do | config |
      #       config.project_key = 'YOUR_AIRBRAKE_PROJECT_KEY'
      #       config.project_id  = 'YOUR_AIRBRAKE_PROJECT_ID'
      #     end
      #
      #     Hoodoo::Services::Middleware::ExceptionReporting.add(
      #       Hoodoo::Services::Middleware::ExceptionReporting::AirbrakeReporter
      #     ) unless Service.config.env.test? || Service.config.env.development?
      #
      # Services and the Hoodoo middleware do not pass Rails-like params
      # around in forms or query strings, but do beware of search or filter
      # query data containing sensitive material or POST bodies in e.g. JSON
      # encoding containing sensitive data. This comes down to the filtering
      # ability of the Airbrake gem:
      #
      #   https://github.com/airbrake/airbrake/wiki/Customizing-your-airbrake.rb
      #
      class AirbrakeReporter < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter

        # Report an exception to Airbrake.
        #
        # +e+::   Exception (or subclass) instance to be reported.
        #
        # +env+:: Optional Rack environment hash for the inbound request,
        #         for exception reports made in the context of Rack request
        #         handling. In the case of Airbrake, the call may just hang
        #         unless a Rack environment is provided.
        #
        def report( e, env )
          opts = { :backtrace => Kernel.caller() }
          opts[ :rack_env ] = env unless env.nil?

          send_synchronously_to_airbrake( e, opts )
        end

        # Report an exception for errors that occur within a fully handled Rack
        # request context, with a high level processed Hoodoo representation
        # available.
        #
        # +e+::       Exception (or subclass) instance to be reported.
        #
        # +context+:: Hoodoo::Services::Context instance describing an
        #             in-flight request/response cycle.
        #
        def contextual_report( e, context )
          opts = {
            :rack_env         => context.owning_interaction.rack_request.env,
            :backtrace        => Kernel.caller(),
            :environment_name => Hoodoo::Services::Middleware.environment,
            :session          => user_data_for( context ) || 'unknown'
          }

          send_synchronously_to_airbrake( e, opts )
        end

      private

        # Send a report to Airbrake using its synchronous mechanism.
        #
        # Since an ExceptionReporter is already a "slow communicatory",
        # Hoodoo is using threads for behaviour; we don't need the async
        # Airbrake mechanism to waste resources doing the same.
        #
        # +e+::      Exception (or subclass) instance to be reported.
        # +params+:: Parameters for <tt>Airbrake#notify_sync</tt>.
        #
        # http://www.rubydoc.info/gems/airbrake-ruby/Airbrake.notify_sync
        # indicates that the +params+ Hash can contain any data of
        # interest; it will be shown in the Airbrake dashboard.
        #
        def send_synchronously_to_airbrake( e, params )
          e = ( e.dup rescue e ) if e.frozen?
          Airbrake.notify_sync( e, params )
        end
      end

    end

  end
end; end
