########################################################################
# File::    by_convention.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Discover - after a fashion - resource endpoint locations
#           by convention, based on Rails-like pluralisation rules. For
#           HTTP-based endpoints. Requires ActiveSupport.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      begin
        require 'active_support/inflector'

        # Discover - after a fashion - resource endpoint locations
        # by convention, based on Rails-like pluralisation rules. For
        # HTTP-based endpoints. Requires ActiveSupport.
        #
        # https://rubygems.org/gems/activesupport
        #
        # See #configure_with for details of required instantiation
        # options. See #discover_remote for the returned data type.
        #
        class ByConvention < Hoodoo::Services::Discovery

          protected

            # Configure an instance. Call via
            # Hoodoo::Services::Discovery::Base#new. Parameters:
            #
            # +options+:: Options hash as described below.
            #
            # Options are:
            #
            # +base_uri+::          A String giving the base URI at which resource
            #                       endpoint implementations can be found. The
            #                       protocol (HTTP or HTTPS), host and port are of
            #                       interest. The path will be overwritten with
            #                       by-convention values for individual resources.
            #
            # +proxy_uri+::         An optional full URI of an HTTP proxy to use if
            #                       the base URI commands use of HTTP or HTTPS. Ruby
            #                       will itself read <tt>ENV['HTTP_PROXY']</tt> if
            #                       set; this option will _override_ that variable.
            #                       Set as a String, as with +base_uri+.
            #
            # +ca_file+::           An optional String indicating a relative or
            #                       absolute file path to the location of a +.pem+
            #                       format Certificate Authority file (trust store),
            #                       which may include multliple certificates. The
            #                       certificates in the file will be used by
            #                       Net::HTTP to validate the SSL ceritificate
            #                       chain presented by remote servers, when calling
            #                       endpoints over HTTPS with Hoodoo::Client.
            #
            #                       Default +nil+ value should be used in nearly all
            #                       cases and uses Ruby OpenSSL defaults which are
            #                       generally Operating System provided.
            #
            # +http_timeout+::      Optional Float indicating the Net::HTTP <b>read</b>
            #                       timeout value. This operates at the HTTP
            #                       transport level and is independent of any
            #                       timeouts set within the API providing server.
            #
            # +http_open_timeout+:: Optional Float indicating the Net::HTTP <b>open</b>
            #                       timeout value. This operates at the HTTP
            #                       transport level and is independent of any
            #                       timeouts set within the API providing server.
            #
            # +routing+::           An optional parameter which gives custom routing
            #                       for exception cases where the by-convention map
            #                       doesn't work. This is usually because there is a
            #                       resource singleton which lives logically at a
            #                       singular named route rather than plural route,
            #                       e.g. "/v1/health" rather than "/v1/healths".
            #
            # The +routing+ parameter is a Hash of Resource names _as_
            # _Symbols_, then values which are Hash of API Version _as_
            # _Integers_ with values that are the Strings giving the
            # full alternative routing path.
            #
            # For example, by convention API version 2 of a Health resource
            # would be routed to "/v2/healths". You would override this to a
            # singular route with this +routing+ parameter Hash:
            #
            #     {
            #       :Health => {
            #         2 => '/v2/health'
            #       }
            #     }
            #
            # This would leave version 1 of the endpoint (or any other version
            # for that matter) still at the by-convention "v<x>/healths" path.
            #
            # Changing the "v<x>" convention for the version part of the path
            # will break Hoodoo compatibility, but this is still allowed in
            # the override in case you have unusual configurations or HTTP
            # layer rewrites that redirect requests to paths that do map down
            # to Hoodoo, or perhaps map to a Hoodoo-like system that's not
            # actually Hoodoo itself but implemented in a compatible fashion.
            #
            def configure_with( options )
              @base_uri          = URI.parse( options[ :base_uri  ] )
              @proxy_uri         = URI.parse( options[ :proxy_uri ] ) unless options[ :proxy_uri ].nil?
              @ca_file           = options[ :ca_file ]
              @http_timeout      = options[ :http_timeout ]
              @http_open_timeout = options[ :http_open_timeout ]
              @routing           = options[ :routing ] || {}
            end

            # Announce the location of an instance. This is really a no-op
            # that runs through and returns the result of #discover_remote.
            #
            # Call via Hoodoo::Services::Discovery::Base#announce.
            #
            # +resource+:: Passed to #discover_remote.
            # +version+::  Passed to #discover_remote.
            # +options+::  Ignored.
            #
            def announce_remote( resource, version, options = {} )
              return discover_remote( resource, version )
            end

            # Using the base URI string from the options in configure_with,
            # underscore and pluralize the resource name with ActiveSupport
            # to produce a path. For example:
            #
            # * Version 3 of resource Member results in
            #   <tt>/v3/members</tt>
            #
            # * Version 2 of resource FarmAnimal results in
            #   <tt>/v2/farm_animals</tt>
            #
            # Returns a Hoodoo::Services::Discovery::ForHTTP instance.
            #
            # The use of ActiveSupport means that pluralisation is subject to
            # the well known Rails limitations and quirks. The behaviour can
            # be overridden using the optional +routing+ parameter in the
            # constructor.
            #
            # Call via Hoodoo::Services::Discovery::Base#discover.
            #
            # +resource+:: Resource name as a _String_.
            # +version+::  Endpoint version as an Integer.
            #
            def discover_remote( resource, version )
              custom_routes = @routing[ resource.to_sym ]

              path = unless custom_routes.nil?
                custom_routes[ version ]
              end

              path ||= "/v#{ version }/#{ resource.to_s.underscore.pluralize }"

              endpoint_uri      = @base_uri.dup
              endpoint_uri.path = path

              return Hoodoo::Services::Discovery::ForHTTP.new(
                resource:          resource,
                version:           version,
                endpoint_uri:      endpoint_uri,
                proxy_uri:         @proxy_uri,
                ca_file:           @ca_file,
                http_timeout:      @http_timeout,
                http_open_timeout: @http_open_timeout
              )
            end

        end

      rescue LoadError
      end

    end
  end
end
