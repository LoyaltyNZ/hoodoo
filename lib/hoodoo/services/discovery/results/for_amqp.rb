########################################################################
# File::    for_amqp.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Describe a resource endpoint location in a way that allows
#           it to be contacted over AMQP (e.g. via Alchemy).
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Describe a resource endpoint location in a way that allows
      # it to be contacted over AMQP (e.g. via Alchemy).
      #
      class ForAMQP

        # The resource name described, as a Symbol (e.g. +:Purchase+).
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # Path at which the resource is expected to be found on the queue
        # (routing via Topic Exchange and Alchemy Flux's translations of
        # paths to keys).
        #
        attr_reader :routing_path

        # Create an instance with named parameters as follows:
        #
        # +resource+:: See #resource.
        # +version+::  See #version.
        #
        def initialize( resource:, version:)

          @resource     = resource.to_sym
          @version      = version.to_i
          @routing_path = Hoodoo::Services::Middleware.de_facto_path_for(
            resource,
            version
          )

        end
      end
    end
  end
end
