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

        # An optional String indicating a relative or absolute file
        # path to the location of a .pem format Certificate
        # Authority file (trust store), which may include multliple
        # certificates. The certificates in the file will be used
        # by Net::HTTP to validate the SSL Ceritificate Chain
        # presented by remote servers, when calling endpoints over
        # HTTPS with Hoodoo::Client.
        #
        # Default +nil+ value should be used in nearly all cases
        # and uses Ruby OpenSSL defaults which are generally
        # Operating System provided.
        #
        attr_accessor :ca_file

        # Optional Float indicating the Net::HTTP read timeout value.
        # This operates at the HTTP transport level and is independent
        # of any timeouts set within the API providing server.
        #
        attr_accessor :http_timeout

        # Create an instance with named parameters as follows:
        #
        # +resource+::     See #resource.
        # +version+::      See #version.
        # +endpoint_uri+:: See #endpoint_uri.
        # +proxy_uri+::    See #proxy_uri. Optional.
        # +ca_file+::      See #ca_file. Optional.
        # +http_timeout+:: See #http_timeout. Optional.
        #
        def initialize( resource:,
                        version:,
                        endpoint_uri:,
                        proxy_uri:    nil,
                        ca_file:      nil,
                        http_timeout: nil )

          self.resource     = resource.to_sym
          self.version      = version.to_i
          self.endpoint_uri = endpoint_uri
          self.proxy_uri    = proxy_uri
          self.ca_file      = ca_file
          self.http_timeout = http_timeout
        end
      end
    end
  end
end
