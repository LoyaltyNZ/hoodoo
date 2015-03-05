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

        # The resource name described, as a String (e.g. "Account").
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # Full URI (as a URI object) at which the resource endpoint
        # implementation can be contacted.
        #
        attr_accessor :endpoint_uri

        # Create an instance with named parameters as follows:
        #
        # +resource+::     See #resource.
        # +version+::      See #version.
        # +endpoint_uri+:: See #endpoint_uri.
        #
        def initialize( resource:,
                        version:,
                        endpoint_uri: )

          self.resource     = resource.to_s
          self.version      = version
          self.endpoint_uri = endpoint_uri
        end
      end
    end
  end
end
