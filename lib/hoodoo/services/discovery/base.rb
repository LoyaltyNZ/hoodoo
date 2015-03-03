module Hoodoo
  module Services
    module Discovery
      class Base

        public

          def initialize( options = {} )
            @known_local_resources = {}
            configure_with( options )
          end

          # Indicate that a resource is available locally and broacast its
          # location to whatever discovery service this subclass supports. The
          # options will be returned by #discover in any _other_ instance, for
          # which the resource endpoint is remote rather than local.
          #
          def announce( resource, version = 1, options = {} )
            resource = resource.to_s
            version  = version.to_i
            result   = announce_remote( resource, version, options )

            @known_local_resources[ key_for( resource, version ) ] = result
            return result
          end

          def discover( resource, version = 1, options = {} )
            resource = resource.to_s
            version  = version.to_i

            if ( is_local?( resource, version ) )
              return @known_local_resources[ key_for( resource, version ) ]
            else
              return discover_remote( resource, version, options )
            end
          end

          def is_local?( resource, version = 1 )
            resource = resource.to_s
            version  = version.to_i

            return @known_local_resources.has_key?( key_for( resource, version ) )
          end

        protected

          def configure_with( options )
            # Implementation is optional and up to subclasses to do.
          end

          def announce_remote( resource, version, options = {} )
            # Implementation is optional and up to subclasses to do.
            true
          end

          def discover_remote( resource, version, options = {} )
            raise "Hoodoo::Services::Discovery::Base subclass does not implement remote discovery required for resource '#{ resource }' / version '#{ version }'"
          end

        private

          def key_for( resource, version )
            "#{ resource }/#{ version }"
          end

      end
    end
  end
end
