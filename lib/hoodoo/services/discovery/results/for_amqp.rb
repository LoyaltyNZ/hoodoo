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

        # The resource name described, as a String (e.g. "Account").
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # Queue name for the target service implementation, as a
        # String (e.g. "service.account").
        #
        attr_accessor :queue_name

        # URL path equivalent that should be mapped to the queue in
        # #queue_name, as a String (e.g. "/v2/accounts").
        #
        attr_accessor :equivalent_path

        # Create an instance with named parameters as follows:
        #
        # +resource+::       See #resource.
        # +version+::        See #version.
        # +queue_name+::     See #queue_name.
        # +equivalent_pat+:: See #equivalent_pat.
        #
        def initialize( resource:,
                        version:,
                        queue_name:,
                        equivalent_path: )

          self.resource        = resource.to_s
          self.version         = version
          self.queue_name      = queue_name
          self.equivalent_path = equivalent_path
        end
      end
    end
  end
end
