module Hoodoo
  module Services
    module Discovery

      # ...returns ForHTTP result...
      #
      class ByDRb < Hoodoo::Services::Discovery::Base

        public

          def flush_services_for_test
            drb_service().flush()
          end

        protected

          def configure( options )
            @drb_port = options[ :drb_port ]
          end

          def announce_remote( resource, version, options = {} )

            host = options[ :host ]
            port = options[ :port ]
            path = options[ :path ]

            # Announce our local services if we managed to find the host and port,
            # but no point otherwise; the values could be anything. In a 'guard'
            # based environment, first-run determines host and port but subsequent
            # runs do not - yet it stays the same, so it works out OK there.
            #
            unless host.nil? || port.nil? || discover_remote( resource, version )
              endpoint_uri_string = "http://#{ host }:#{ port }#{ path }"
              drb_service().add( resource, version, endpoint_uri_string )
            end
          end

          def discover_remote( resource, version, options = {} )
            endpoint_uri_string = drb_service().find( resource, version )

            if endpoint_uri_string.nil?
              return nil
            else
              return Hoodoo::Services::Discovery::DiscoveryResultForHTTP.new(
                resource:     resource,
                version:      version,
                endpoint_uri: URI.parse( endpoint_uri_string )
              )
            end
          end

        private

          def drb_service

            # Attempt to contact the DRb server daemon. If it can't be
            # contacted, try to start it first, then connect.

            drb_uri = Hoodoo::Services::Discovery::ByDRb::DRbServer.uri( @drb_port )
            DRb.start_service

            begin
              drb_service = DRbObject.new_with_uri( drb_uri )
              drb_service.ping()

            rescue DRb::DRbConnError
              script_path = File.join( File.dirname( __FILE__ ), 'drb_server_start.rb' )
              Process.detach( spawn( "bundle exec ruby '#{ script_path }'" ) )

              begin
                Timeout::timeout( 5 ) do
                  loop do
                    begin
                      drb_service = DRbObject.new_with_uri( drb_uri )
                      drb_service.ping()
                      break
                    rescue DRb::DRbConnError
                      sleep 0.1
                    end
                  end
                end

              rescue Timeout::Error
                raise "Hoodoo::Services::Discovery::ByDRb timed out while waiting for DRb service registry to start"

              end
            end

            return drb_service
          end

      end
    end
  end
end
