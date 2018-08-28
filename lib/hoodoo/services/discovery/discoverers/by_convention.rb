########################################################################
# File::    by_convention.rb
# (C)::     Loyalty New Zealand 2018
#
# Purpose:: Discover resource endpoint locations by convention
#
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      begin
        # Discover - after a fashion - resource endpoint locations
        # by convention. For HTTP-based endpoints.
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
            # +base_uri+::          A String giving the base URI at which
            #                       resource endpoint implementations can be
            #                       found. The protocol (HTTP or HTTPS), host
            #                       and port are of interest. The path will be
            #                       overwritten with by-convention values for
            #                       individual resources.
            #
            # +proxy_uri+::         An optional full URI of an HTTP proxy to
            #                       use if the base URI commands use of HTTP or
            #                       HTTPS. Ruby will itself read
            #                       <tt>ENV['HTTP_PROXY']</tt> if set; this
            #                       option _overrides_ that variable. Set as a
            #                       String, as with +base_uri+.
            #
            # +ca_file+::           An optional String indicating a relative or
            #                       absolute file path to the location of a
            #                       +.pem+ format Certificate Authority file
            #                       (trust store), which may include multliple
            #                       certificates. The certificates in the file
            #                       will be used by Net::HTTP to validate the
            #                       SSL ceritificate chain presented by remote
            #                       servers, when calling endpoints over HTTPS
            #                       with Hoodoo::Client.
            #
            #                       The default +nil+ value should be used in
            #                       nearly all cases and uses Ruby OpenSSL
            #                       defaults which are generally Operating
            #                       System provided.
            #
            # +http_timeout+::      Optional Float providing a Net::HTTP read
            #                       timeout value, when calling endpoints over
            #                       HTTPS with Hoodoo::Client. This is a value
            #                       in seconds (default 60) that the client
            #                       allows for any TCP read operation. It
            #                       operates at the HTTP transport level and is
            #                       independent of any higher level timeouts
            #                       that might be set up.
            #
            # +http_open_timeout+:: Optional Float providing a Net::HTTP open
            #                       timeout value, when calling endpoints over
            #                       HTTPS with Hoodoo::Client. This is a value
            #                       in seconds (default 60) that the client
            #                       allows for any TCP connection attempt. It
            #                       operates at the HTTP transport level and is
            #                       independent of any higher level timeouts
            #                       that might be set up.
            #
            def configure_with( options )
              @base_uri          = URI.parse( options[ :base_uri  ] )
              @proxy_uri         = URI.parse( options[ :proxy_uri ] ) unless options[ :proxy_uri ].nil?

              @ca_file           = options[ :ca_file           ]
              @http_timeout      = options[ :http_timeout      ]
              @http_open_timeout = options[ :http_open_timeout ]
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
            # along with the version and resource name to produce a path.
            # For example:
            #
            # * Version 3 of resource Member results in
            #   <tt>/3/Member</tt>
            #
            # * Version 2 of resource FarmAnimal results in
            #   <tt>/2/FarmAnimal</tt>
            #
            # Returns a Hoodoo::Services::Discovery::ForHTTP instance.
            #
            # Call via Hoodoo::Services::Discovery::Base#discover.
            #
            # +resource+:: Resource name as a _String_.
            # +version+::  Endpoint version as an Integer.
            #
            def discover_remote( resource, version )
              path = "/#{ version }/#{ resource.to_s }"

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
