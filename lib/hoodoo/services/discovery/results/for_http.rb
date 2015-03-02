module Hoodoo
  module Services
    module Discovery
      class ForHTTP

        attr_accessor :resource
        attr_accessor :version
        attr_accessor :endpoint_uri

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
