########################################################################
# File::    base.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support resource endpoint discovery.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    module Discovery

      # Base class for discovery code.
      #
      # Implementations of service announcement and discovery code should
      # subclass from this, then optionally implement
      # ::configure_with and ::announce_remote, and always implement
      # ::discover_remote.
      #
      class Base

        public

          # Create a new instance.
          #
          # +options+:: Passed to the subclass in use via ::configure_with.
          #             Subclasses define their options. Only instantiate
          #             such subclasses, not this 'Base' class; see the
          #             subclass documentation for option details.
          #
          def initialize( options = {} )
            @known_local_resources = {}
            configure_with( options )
          end

          # Indicate that a resource is available locally and broacast its
          # location to whatever discovery service a subclass supports via
          # ::announce_remote.
          #
          # +resource+:: Resource name as a Symbol or String
          #              (e.g. "Account").
          #
          # +version+::  Endpoint version as an Integer; optional; default
          #              is 1.
          #
          # +options+::  Defined by whatever subclass is in use. See that
          #              subclass's documentation for details.
          #
          # Returns the result of calling #announce_remote (in the subclass
          # in use) with the same parameters.
          #
          def announce( resource, version = 1, options = {} )
            resource = resource.to_s
            version  = version.to_i
            result   = announce_remote( resource, version, options )

            @known_local_resources[ key_for( resource, version ) ] = result
            return result
          end

          # Find a resource endpoint. This may be recorded locally or
          # via whatever remote discovery mechanism a subclass implements.
          #
          # +resource+:: Resource name as symbol or string (e.g. "Account").
          #
          # +version+::  Endpoint version as an Integer; optional; default
          #              is 1.
          #
          # +options+::  Defined by whatever subclass is in use. See that
          #              subclass's documentation for details.
          #
          # Returns the result of calling #discover_remote (in the subclass
          # in use) with the same parameters.
          #
          # Use #is_local? if you need to know that an endpoint was
          # announced through this same instance ("locally").
          #
          def discover( resource, version = 1, options = {} )
            resource = resource.to_s
            version  = version.to_i

            if ( is_local?( resource, version ) )
              return @known_local_resources[ key_for( resource, version ) ]
            else
              return discover_remote( resource, version, options )
            end
          end

          # Was a resource announced in this instance ("locally")? Returns
          # +true+ if so, else +false+.
          #
          # +resource+:: Resource name as symbol or string (e.g. "Account").
          #
          # +version+::  Endpoint version as an Integer; optional; default
          #              is 1.
          #
          def is_local?( resource, version = 1 )
            resource = resource.to_s
            version  = version.to_i

            return @known_local_resources.has_key?( key_for( resource, version ) )
          end

        protected

          # Configure a new instance. Subclasses optionally implement this
          # method to store configuration information relevant to that
          # subclass. Subclasses must document their options.
          #
          # +options+:: See subclass documentation for option details.
          #
          def configure_with( options )
            # Implementation is optional and up to subclasses to do.
          end

          # Announce a resource endpoint. Subclasses optionally implement
          # this method to broadcast information to other instances of the
          # same subclass by some subclass-implemented mechanism.
          #
          # Discovery instance users do not call this method directly.
          # Call #announce instead.
          #
          # Subclasses must return a
          # Hoodoo::Services::Discovery::ForHTTP or
          # Hoodoo::Services::Discovery::ForAMQP instance in response to
          # this call, giving the HTTP details required to contact the
          # endpoint, or AMQP (on-queue) details required to contact the
          # endpoint, respectively.
          #
          # +resource+:: Resource name as a String.
          # +version+::  Endpoint version as an Integer.
          # +options+::  See subclass documentation for option details.
          #
          def announce_remote( resource, version, options = {} )
            # Implementation is optional and up to subclasses to do.
            true
          end

          # Discover the location of a resource endpoint. Subclasses _must_
          # implement this method to retrieve information about the location
          # of resource endpoints by some subclass-implemented mechanism.
          #
          # Discovery instance users do not call this method directly.
          # Call #discover instead.
          #
          # Subclasses must return either +nil+ if the endpoint is not
          # found, or a Hoodoo::Services::Discovery::ForHTTP or
          # Hoodoo::Services::Discovery::ForAMQP instance giving the HTTP
          # details required to contact the endpoint, or AMQP (on-queue)
          # details required to contact the endpoint, respectively.
          #
          # +resource+:: Resource name as a String.
          # +version+::  Endpoint version as an Integer.
          # +options+::  See subclass documentation for option details.
          #
          def discover_remote( resource, version, options = {} )
            raise "Hoodoo::Services::Discovery::Base subclass does not implement remote discovery required for resource '#{ resource }' / version '#{ version }'"
          end

        private

          # For a given resource and version, return a key for the internal
          # Hash of locally announced resources.
          #
          # +resource+:: Resource name as a String.
          # +version+::  Endpoint version as an Integer.
          #
          def key_for( resource, version )
            "#{ resource }/#{ version }"
          end

      end
    end
  end
end
