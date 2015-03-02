module Hoodoo
  module Services
    module Discovery

      begin
        require 'active_support/inflector'

        # ...returns ForHTTP result...
        #
        class ByConvention < Hoodoo::Services::Discovery::Base

          protected

            def configure_with( options )
              @base_uri = URI.parse( options[ :base_uri ] )
            end

            def discover_remote( resource, version, options = {} )
              path = "/v#{ version }/#{ resource.to_s.underscore.pluralize }"

              endpoint_uri      = @base_uri.dup
              endpoint_uri.path = path

              return Hoodoo::Services::Discovery::DiscoveryResultForHTTP.new(
                resource:     resource,
                version:      version,
                endpoint_uri: endpoint_uri
              )
            end
        end

      rescue LoadError
      end

    end
  end
end
