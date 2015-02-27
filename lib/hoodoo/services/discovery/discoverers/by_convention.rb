module Hoodoo
  module Services
    module Discovery

      begin
        require 'active_support/infector'

        class ByConvention < Hoodoo::Services::Discovery::BaseForHTTP

          public

            def initialize( options = {} )
              @base_uri = options[ :base_uri ]
            end

          protected

            def discover_remote( resource, version, options = {} )
              @base_uri/v/foos




            end
        end

      rescue LoadError
      end

    end
  end
end
