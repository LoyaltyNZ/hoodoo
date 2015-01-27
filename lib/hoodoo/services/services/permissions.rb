########################################################################
# File::    permissions.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Allow/ask/deny support for resources and actions.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Created.
########################################################################

module Hoodoo; module Services

  # The Permissions class provides a way to store and recall information on
  # action behaviour for resources. It is just a way to store and query this
  # information; actually enforcing the result is up to the caller.
  #
  # Permissions are based on the standard actions - +list+, +show+, +create+,
  # +update+ and +delete+ - with defined permissions of constants DENY
  # (prohibit access), ALLOW (allow access) and ASK. The intention of ASK is
  # that some other component - usually a service application - should be
  # passed details of the request and asked if it should be permitted.
  #
  # Callers must *ensure* they *only* use the DENY, ALLOW and ASK constants
  # defined herein, without making assumptions about their assigned values.
  #
  # There is both a default set of permissions in addition to per-resource
  # permissions and there is a fallback for cases where a permission for a
  # particular action has not been defined. This lets you define the baseline
  # behaviour in the fallback cases and only describe exceptions to that
  # baseline through the Permissions interface, minimising caller workload.
  #
  # Hoodoo::Services::Middleware uses an instance of this class to determine
  # whether or not it should pass on inbound requests to service applications.
  #
  # Example:
  #
  # Here, an object is created with a default fallback of DENY, then has the
  # action "list" allowed for all resources and says that resource "Member"
  # must ask someone for permission if its "show" action is requested.
  # Another resource "Ping" allows any action unconditionally.
  #
  #     p = Hoodoo::Services::Permissions.new
  #     p.set_default( :list, Hoodoo::Services::Permissions::ALLOW )
  #     p.set_resource( :Member, :show, Hoodoo::Services::Permissions::ASK )
  #     p.set_resource_fallback( :Ping, Hoodoo::Services::Permissions::ALLOW )
  #
  #     puts JSON.pretty_generate( p.to_h() )
  #
  #     # Yields...
  #     #
  #     # {
  #     #   "default": {
  #     #     "else": "deny",
  #     #     "actions": {
  #     #       "list": "allow"
  #     #     }
  #     #   },
  #     #   "resources": {
  #     #     "Member": {
  #     #       "actions": {
  #     #         "show": "ask"
  #     #       }
  #     #     },
  #     #     "Ping": {
  #     #       "else": "allow"
  #     #     }
  #     #   }
  #     # }
  #
  class Permissions

    # Permission is denied; the action should not be permitted.
    #
    DENY  = 'deny'

    # Permission is granted; the action should be permitted.
    #
    ALLOW = 'allow'

    # Something else (e.g. a service application) needs to be asked to see if
    # it permits the action.
    #
    ASK   = 'ask'

    # Create a new Permissions instance, optionally from a Hash of the format
    # returned by #to_h.
    #
    # By default the object is initialised with a default fallback which
    # denies all actions for all resources.
    #
    def initialize( hash = nil )
      if hash.nil?
        @permissions = {}
        set_default_fallback( DENY )
      else
        from_h( hash )
      end
    end

    # Set the default fallback for actions. If a resource does not have a
    # specific entry for it in the Permissions object and if the action does
    # not have a default permission, then this permission used.
    #
    # +permission+:: DENY, ALLOW or ASK.
    #
    def set_default_fallback( permission )
      action_name = action_name.to_s

      @permissions[ 'default' ] ||= {}
      @permissions[ 'default' ][ 'else' ] = permission
    end

    # Set the default permission for the given action. If a resource does not
    # have a specific entry for it in the Permissions object but the action
    # matches the given name, then this permission is used.
    #
    # +action_name+:: Action as a String or Symbol, from: +list+, +show+,
    #                 +create+, +update+ or +delete+.
    #
    # +permission+::  DENY, ALLOW or ASK.
    #
    def set_default( action_name, permission )
      action_name = action_name.to_s

      @permissions[ 'default' ] ||= {}
      @permissions[ 'default' ][ 'actions' ] ||= {}
      @permissions[ 'default' ][ 'actions' ][ action_name ] = permission
    end

    # Set the default fallback for a resource. If the resource is asked to
    # perform an action that's not otherwise listed in the resource's entry
    # in the Permissions object, then this permission is used.
    #
    # +resource_name+:: Resource name as a Symbol or String, e.g. "+Purchase+"
    #                   or +:Member+.
    #
    # +action_name+::   Action as a String or Symbol, from: +list+, +show+,
    #                   +create+, +update+ or +delete+.
    #
    # +permission+::    DENY, ALLOW or ASK.
    #
    def set_resource_fallback( resource_name, permission )
      resource_name = resource_name.to_s

      @permissions[ 'resources' ] ||= {}
      @permissions[ 'resources' ][ resource_name ] ||= {}
      @permissions[ 'resources' ][ resource_name ][ 'else' ] = permission
    end

    # Set the permissions an action on a resource.
    #
    # +resource_name+:: Resource name as a Symbol or String, e.g. "+Purchase+"
    #                   or +:Member+.
    #
    # +permission+::   DENY, ALLOW or ASK.
    #
    def set_resource( resource_name, action_name, permission )
      resource_name = resource_name.to_s
      action_name   = action_name.to_s

      @permissions[ 'resources' ] ||= {}
      @permissions[ 'resources' ][ resource_name ] ||= {}
      @permissions[ 'resources' ][ resource_name ][ 'actions' ] ||= {}
      @permissions[ 'resources' ][ resource_name ][ 'actions' ][ action_name ] = permission
    end

    # For the given resource, is the given action permitted? Returns one of the
    # ALLOW, DENY or ASK constant values.
    #
    # +resource_name+:: Resource name as a Symbol or String, e.g. "+Purchase+"
    #                   or +:Member+.
    #
    # +action_name+::   Action as a String or Symbol, from: +list+, +show+,
    #                   +create+, +update+ or +delete+.
    #
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

    # Return a Hash representative of this permissions object, which can be
    # stored elsewhere, used to initialise another instance or written to an
    # existing instance with #from_h.
    #
    def to_h
      @permissions
    end

    # Overwrite this instances's permissions with those from the given Hash.
    #
    # +hash+:: Permissions hash, which must come (directly or indirectly) from
    #          a #to_h call.
    #
    def from_h( hash )
      @permissions = hash
    end

  end

end; end
