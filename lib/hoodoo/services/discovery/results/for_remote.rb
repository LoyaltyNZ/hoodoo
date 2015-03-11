########################################################################
# File::    for_remote.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Describe a "pseudo" resource endpoint location in terms of
#           an interation context and wrapped "real" endpoint instance.
# ----------------------------------------------------------------------
#           10-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Describe a "pseudo" resource endpoint location in terms of
      # an interation context and wrapped "real" endpoint instance.
      #
      # This is a very special case class used for wrapping endpoints in, for
      # example, the inter-resource remote call code in the middleware and in
      # the auto-session code in Hoodoo::Client::Endpoint::AutoSession.
      #
      class ForRemote

        # The resource name described, as a Symbol (e.g. +:Purchase+).
        #
        attr_accessor :resource

        # Resource endpoint version, as an Integer (e.g. 2).
        #
        attr_accessor :version

        # A wrapped Endpoint class, which will be used for the *actual* call
        # to the remote resource, after pre/post-processing in the context of
        # #source_interaction (e.g. augmenting session permissions with
        # source-resource-interface-specified additions necessary to call the
        # target remote resource).
        #
        attr_accessor :wrapped_endpoint

        # Create an instance with named parameters as follows:
        #
        # +resource+::         See #resource.
        # +version+::          See #version.
        # +wrapped_endpoint+:: See #wrapped_endpoint.
        #
        def initialize( resource:,
                        version:,
                        wrapped_endpoint: )

          self.resource         = resource.to_sym
          self.version          = version.to_i
          self.wrapped_endpoint = wrapped_endpoint
        end
      end
    end
  end
end
