########################################################################
# File::    for_local.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Describe a resource endpoint location in a way that allows
#           it to be method-called from the service middleware directly.
# ----------------------------------------------------------------------
#           10-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Describe a resource endpoint location in a way that allows
      # it to be method-called from the service middleware directly.
      #
      # This is a very special case class used for the inter-resource
      # local call code in Hoodoo::Services::Middleware. It really
      # exists only for semantic purposes; the middleware calls via
      # Hoodoo::Client::Endpoint subclass,
      # Hoodoo::Sevices::Middleware::InterResourceLocal; and the
      # Endpoint subclass family are supposed to use result classes
      # from the Hoodoo::Services::Discovery engine when they
      # configure instances. This isn't actually enforced anywhere,
      # but conceptually it's cleanest to follow the same pattern.
      #
      class ForLocal

        # The resource name described, as a Symbol (e.g. +:Purchase+).
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # The base path of this resource and version - for example,
        # "/v1/products" or "/v2/members". String.
        #
        attr_accessor :base_path

        # A regular expression which matches the +base_path+ and any
        # identifier data, allowing inbound URI-based requests to be
        # routed to this endpoint. Regexp instance.
        #
        attr_accessor :routing_regexp

        # The Hoodoo::Services::Interface subclass _class_ describing the
        # resource interface.
        #
        attr_accessor :interface_class

        # The Hoodoo::Services::Implementation subclass _instance_
        # which implements the interface described by +interface_class+.
        #
        attr_accessor :implementation_instance

        # Create an instance with named parameters as follows:
        #
        # +resource+::                See #resource.
        # +version+::                 See #version.
        # +base_path+::               See #base_path.
        # +routing_regexp+::          See #routing_regexp.
        # +interface_class+::         See #interface_class.
        # +implementation_instance+:: See #implementation_instance.
        #
        def initialize( resource:,
                        version:,
                        base_path:,
                        routing_regexp:,
                        interface_class:,
                        implementation_instance: )

          self.resource                = resource.to_sym
          self.version                 = version.to_i
          self.base_path               = base_path
          self.routing_regexp          = routing_regexp
          self.interface_class         = interface_class
          self.implementation_instance = implementation_instance
        end
      end
    end
  end
end
