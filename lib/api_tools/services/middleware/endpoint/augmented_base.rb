########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::ServiceMiddleware::ServiceEndpoint family of
#           inter-resource calls.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class ServiceMiddleware
    class ServiceEndpoint < Hoodoo::ServiceMiddleware

      # Base mixin for
      # Hoodoo::ServiceMiddleware::ServiceEndpoint::AugmentedHash and
      # Hoodoo::ServiceMiddleware::ServiceEndpoint::AugmentedArray,
      # used by Hoodoo::ServiceMiddleware::ServiceEndpoint for return
      # values in its resource calling API - see
      # Hoodoo::ServiceMiddleware::ServiceEndpoint#list,
      # Hoodoo::ServiceMiddleware::ServiceEndpoint#show,
      # Hoodoo::ServiceMiddleware::ServiceEndpoint#create,
      # Hoodoo::ServiceMiddleware::ServiceEndpoint#update and
      # Hoodoo::ServiceMiddleware::ServiceEndpoint#delete.
      #
      # The error handling mechanism this mixin provides is intentionally
      # analogous to that used for mapping ActiveRecord model validation
      # failures to platform errors in Hoodoo::ActiveRecord::ErrorMapping.
      #
      module AugmentedBase

        # Adds errors set via #set_platform_errors to the
        # given Hoodoo::Errors instance. Generally, #set_platform_errors is
        # only ever called by the middleware when one resource calls another
        # resource via Hoodoo::ServiceContext#resource and the methods in
        # the Hoodoo::ServiceMiddleware::ServiceEndpoint instance it
        # returns.
        #
        # Returns +true+ if any errors were added else +false+ if everything
        # is OK (no platform errors have been noted internally).
        #
        # This makes the idiomatic example for "make inter-resource call,
        # add any errors to my service's response and return on error" very
        # simple, at the expense of modifying the passed-in error collection
        # contents (mutating a parameter is a risky pattern). For an
        # alternative pattern which avoids this, see #platform_errors.
        #
        # Otherwise, a hypothetical resource +Member+ could be listed as
        # follows, as part of a hypothetical +show+ implementation of some
        # other resource:
        #
        #     def show( context )
        #       list = context.resource( :Member ).list()
        #       return if list.adds_errors_to?( context.response.errors )
        #       # ...
        #     end
        #
        # +collection+:: An Hoodoo::Errors instance, typically obtained
        #                from the Hoodoo::ServiceContext instance passed to
        #                a service implementation in calls like
        #                Hoodoo::ServiceImplementation#list or
        #                Hoodoo::ServiceImplementation#show, via
        #                +context.response.errors+
        #                (i.e. Hoodoo::ServiceContext#response /
        #                Hoodoo::ServiceResponse#errors). The collection you
        #                pass is updated with any errors noted internally via
        #                (usually-middleware-automatically-called) method
        #                #set_platform_errors.
        #
        def adds_errors_to?( collection )
          to_add = self.platform_errors()

          if to_add.has_errors?
            collection.merge!( to_add )
            return true
          else
            return false
          end
        end

        # Returns an Hoodoo::Errors instance that's either been assigned
        # via #set_platform_errors or is an empty, internally assigned
        # collection. This method is very closely related to
        # #adds_errors_to? and, if you have not already done so, you should
        # read that method's documentation before continuing.
        #
        # The #platform_errors method supports a slightly more verbose form
        # of error handling for inter-resource calls that avoids changing a
        # passed in parameter in the manner of #adds_errors_to?. Compare the
        # idiom shown there:
        #
        #     return if list.adds_errors_to?( context.response.errors )
        #
        # ...with the idiomatic use of this method:
        #
        #     context.response.add_errors( list.platform_errors )
        #     return if context.response.halt_processing?
        #
        # It is a little more verbose and very slightly less efficient as it
        # involves more method calls end to end, but you may prefer the
        # conceptually cleaner code.
        #
        def platform_errors
          @nz_co_loyalty_platform_errors ||= Hoodoo::Errors.new
        end

        # Sets the Hoodoo::Errors instance used by #adds_errors_to? or
        # returned by #platform_errors.
        #
        # It is expected that only Hoodoo middleware code will call this
        # method as part of inter-resource call handling for the internal
        # use cases of this class, though client code may find other uses
        # that are independent of the inter-resource call case wherein the
        # method may be safely invoked.
        #
        def set_platform_errors( errors )
          @nz_co_loyalty_platform_errors = errors
        end
      end
    end
  end
end
