########################################################################
# File::    for_http.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Describe a resource endpoint location in a way that allows
#           it to be contacted over HTTP.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Describe a resource endpoint location in a way that allows
      # it to be contacted over HTTP.
      #
      class ForHTTP

        # The resource name described, as a Symbol (e.g. +:Purchase+).
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # Full URI (as a URI object) at which the resource endpoint
        # implementation can be contacted.
        #
        attr_accessor :endpoint_uri

        # Full URI (as a URI object) of an HTTP proxy to use as an
        # override to <tt>ENV['HTTP_PROXY']</tt> which Ruby itself
        # will otherwise read. Will be +nil+ for no proxy override.
        #
        attr_accessor :proxy_uri

        # String - relative or absolute path to a CA-File that will
        # be used for validating the SSL Cert presented by the server
        # by Hoodoo::Client when making calls over https. leave as nil
        # to let ruby default to the standard ca-certs provided by the
        # operating system.
        #
        attr_accessor :ca_file

        # Create an instance with named parameters as follows:
        #
        # +resource+::     See #resource.
        # +version+::      See #version.
        # +endpoint_uri+:: See #endpoint_uri.
        # +proxy_uri+::    See #proxy_uri.
        #
        def initialize( resource:,
                        version:,
                        endpoint_uri:,
                        proxy_uri: nil,
                        ca_file: nil )

          self.resource     = resource.to_sym
          self.version      = version.to_i
          self.endpoint_uri = endpoint_uri
          self.proxy_uri    = proxy_uri
          self.ca_file      = ca_file
        end
      end
    end
  end
end
