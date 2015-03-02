module Hoodoo
  module Services
    module Discovery
      class Base

        public

          def initialize( options = {} )
            @configuration_options = options
            @known_local_resources = {}

            configure_with( options )
          end

          # Indicate that a resource is available locally and broacast its
          # location to whatever discovery service this subclass supports. The
          # options will be returned by #discover in any _other_ instance, for
          # which the resource endpoint is remote rather than local.
          #
          def announce( resource, version = 1, options = {} )
            @known_local_resources[ key_for( resource, version ) ] = options
            announce_remote( resource, version, options )
          end

          # return :local  => <whatever options were in #announce>
          #     or :remote => <something else defined by subclass you're calling>
          #
          def discover( resource, version = 1, options = {} )
            local_key = key_for( resource, version )

            if ( @known_local_resources.has_key?( local_key ) )
              return { :local => @known_local_resources[ local_key ] }
            else
              return discover_remote( resource, version, options )
            end
          end

        protected

          def configure_with( options )
            # Implementation is optional and up to subclasses to do.
          end

          def announce_remote( resource, version, options = {} )
            # Implementation is optional and up to subclasses to do.
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
