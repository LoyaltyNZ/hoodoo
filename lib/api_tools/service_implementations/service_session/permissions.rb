module ApiTools
  class ServiceSession
    class Permissions

      DENY  = 'deny'
      ALLOW = 'allow'
      ASK   = 'ask'

      def initialize( hash = nil )
        if hash.nil?
          @permissions = {}
          set_default_fallback( DENY )
        else
          from_h( hash )
        end
      end

      def set_default_fallback( permission )
        action_name = action_name.to_s

        @permissions[ 'default' ] ||= {}
        @permissions[ 'default' ][ 'else' ] = permission
      end

      def set_default( action_name, permission )
        action_name = action_name.to_s

        @permissions[ 'default' ] ||= {}
        @permissions[ 'default' ][ 'actions' ] ||= {}
        @permissions[ 'default' ][ 'actions' ][ action_name ] = permission
      end

      def set_resource_fallback( resource_name, permission )
        resource_name = resource_name.to_s

        @permissions[ 'resources' ] ||= {}
        @permissions[ 'resources' ][ resource_name ] ||= {}
        @permissions[ 'resources' ][ resource_name ][ 'else' ] = permission
      end

      def set_resource( resource_name, action_name, permission )
        resource_name = resource_name.to_s
        action_name   = action_name.to_s

        @permissions[ 'resources' ] ||= {}
        @permissions[ 'resources' ][ resource_name ] ||= {}
        @permissions[ 'resources' ][ resource_name ][ 'actions' ] ||= {}
        @permissions[ 'resources' ][ resource_name ][ 'actions' ][ action_name ] = permission
      end

      def permitted?( resource_name, action_name )
        resource_name = resource_name.to_s
        action_name   = action_name.to_s

        tree = if @permissions.has_key?( 'resources' )
          @permissions[ 'resources' ][ resource_name ]
        end

        tree ||= @permissions[ 'default' ] || {}

        result = if tree.has_key?( 'actions' )
          tree[ 'actions' ][ action_name ]
        end

        return result || tree[ 'else' ]
      end

      def to_h
        @permissions
      end

      def from_h( hash )
        @permissions = hash
      end

    end
  end
end
