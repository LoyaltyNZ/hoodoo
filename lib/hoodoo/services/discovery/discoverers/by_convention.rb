########################################################################
# File::    by_convention.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Discover - after a fashion - resource endpoint locations
#           by convention, based on Rails-like pluralisation rules. For
#           HTTP-based endpoints. Requires ActiveSupport.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      begin
        require 'active_support/inflector'

        # Discover - after a fashion - resource endpoint locations
        # by convention, based on Rails-like pluralisation rules. For
        # HTTP-based endpoints. Requires ActiveSupport.
        #
        # https://rubygems.org/gems/activesupport
        #
        # See #configure_with for details of required instantiation
        # options. See #discover_remote for the returned data type.
        #
        class ByConvention < Hoodoo::Services::Discovery

          protected

            # Configure an instance. Call via
            # Hoodoo::Services::Discovery::Base#new. Parameters:
            #
            # +options+:: Options hash as described below.
            #
            # Options are:
            #
            # +base_uri+:: A String giving the base URI at which resource
            #              endpoint implementations can be found. The
            #              protocol (HTTP or HTTPS), host and port are of
            #              interest. The path will be overwritten with
            #              by-convention values for individual resources.
            #
            def configure_with( options )
              @base_uri = URI.parse( options[ :base_uri ] )
            end

            # Announce the location of an instance. This is really a no-op
            # that runs through and returns the result of #discover_remote.
            #
            # Call via Hoodoo::Services::Discovery::Base#announce.
            #
            # +resource+:: Passed to #discover_remote.
            # +version+::  Passed to #discover_remote.
            # +options+::  Ignored.
            #
            def announce_remote( resource, version, options = {} )
              return discover_remote( resource, version )
            end

            # Using the base URI string from the options in configure_with,
            # underscore and pluralize the resource name with ActiveSupport
            # to produce a path. For example:
            #
            # * Version 3 of resource Member results in
            #   <tt>/v3/members</tt>
            #
            # * Version 2 of resource FarmAnimal results in
            #   <tt>/v2/farm_animals</tt>
            #
            # Returns a Hoodoo::Services::Discovery::ForHTTP instance.
            #
            # The use of ActiveSupport means that pluralisation is subject
            # to the well known Rails limitations and quirks.
            #
            # Call via Hoodoo::Services::Discovery::Base#discover.
            #
            # +resource+:: Resource name as a String.
            # +version+::  Endpoint version as an Integer.
            # +options+::  Ignored.
            #
            def discover_remote( resource, version, options = {} )
              path = "/v#{ version }/#{ resource.to_s.underscore.pluralize }"

              endpoint_uri      = @base_uri.dup
              endpoint_uri.path = path

              return Hoodoo::Services::Discovery::ForHTTP.new(
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
