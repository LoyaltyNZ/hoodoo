########################################################################
# File::    error_mapping.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing a mapping between API level errors and model
#           validation errors.
# ----------------------------------------------------------------------
#           17-Nov-2014 (ADH): Created.
#           12-Dec-2018 (ADH): Moved most of the error mapping code out
#                              to Hoodoo::ActiveRecord::Support, so that
#                              it can be reused more easily.
########################################################################

require 'hoodoo/active/active_record/support'

module Hoodoo

  # Support mixins for models subclassed from ActiveRecord::Base. See:
  #
  # * http://guides.rubyonrails.org/active_record_basics.html
  #
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # a mapping between ActiveRecord validation errors and platform errors
    # via Hoodoo::ErrorDescriptions and Hoodoo::Errors. See individual
    # module methods for examples, along with:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    # The error handling mechanism this mixin provides is intentionally
    # analogous to that used for resource-to-resource calls through
    # Hoodoo::Client::AugmentedBase.
    #
    module ErrorMapping

      # Validates the model instance and adds mapped-to-platform errors to
      # a given Hoodoo::Errors instance, if any validation errors occur.
      # For ActiveRecord validation documentation, see:
      #
      # * http://guides.rubyonrails.org/active_record_validations.html
      #
      # Returns +true+ if any errors were added (model instance is invalid)
      # else +false+ if everything is OK (model instance is valid).
      #
      # Uses Hoodoo::ActiveRecord::Support#translate_errors_on to perform
      # the mapping. For detailed information on how the mapping works,
      # please see that method.
      #
      # == Mapping ActiveRecord errors to Hoodoo errors
      #
      # The method makes an idiomatic example for "check errors in the model,
      # map them to platform errors in my service's response and return the
      # result" very simple, at the expense of modifying the passed-in
      # error collection contents (mutating a parameter is a risky pattern).
      #
      # Given this example model:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::ErrorMapping
      #       # ...
      #     end
      #
      # ...then a service's #create method could do something like:
      #
      #     def create( context )
      #
      #       # Validate inbound creation data by e.g. schema through the
      #       # presenter layer - Hoodoo::Presenters::Base and
      #       # Hoodoo::Presenters::Base - then...
      #
      #       model         = SomeModel.new
      #       model.param_1 = 'something based on inbound creation data'
      #
      #       # Ideally use the Writer mixin for concurrency-safe saving,
      #       # but in this simple example we'll just use #save directly;
      #       # unhandled database exceptions might be thrown:
      #
      #       model.save()
      #
      #       # Now exit, adding mapped errors to the response, if there
      #       # were validation failures when attempting to save.
      #
      #       return if model.adds_errors_to?( context.response.errors )
      #
      #       # ...else set 'context.response' data appropriately.
      #
      #     end
      #
      # An alternative pattern which avoids mutating the input parameter
      # uses the potentially less efficient, but conceptually cleaner method
      # #platform_errors. Using #adds_errors_to? as per the above code is
      # faster, but the above example's use of +save+, as per its comments,
      # does not fully handle some concurrency edge cases.
      #
      # To win on both fronts use Hoodoo::ActiveRecord::Writer:
      #
      #     def create( context )
      #
      #       model         = SomeModel.new
      #       model.param_1 = 'something based on inbound creation data'
      #
      #       unless model.persist_in( context ).equal?( :success )
      #         context.response.add_errors( model.platform_errors )
      #         return
      #       end
      #
      #       # ...else set 'context.response' data appropriately.
      #
      #     end
      #
      # In this case, the less efficient #platform_errors call only happens
      # when we know we are in an error recovery situation anyway, in which
      # case it isn't as important to operate in as efficient a manner as
      # possible - provided one assumes that the non-error path is the much
      # more common case!
      #
      # +collection+:: A Hoodoo::Errors instance, typically obtained
      #                from the Hoodoo::Services::Context instance passed to
      #                a service implementation in calls like
      #                Hoodoo::Services::Implementation#list or
      #                Hoodoo::Services::Implementation#show, via
      #                +context.response.errors+
      #                (i.e. Hoodoo::Services::Context#response /
      #                Hoodoo::Services::Response#errors). The collection you
      #                pass is updated if there are any errors recorded in
      #                the model, by adding equivalent structured errors to
      #                the collection.
      #
      def adds_errors_to?( collection )
        self.validate()
        Hoodoo::ActiveRecord::Support.translate_errors_on( self, collection )

        return self.errors.any?
      end

      # Validate the model instance and return a Hoodoo::Errors instance
      # which contains no platform errors if there are no model validation
      # errors, else mapped-to-platform errors if validation errors are
      # encountered. For ActiveRecord validation documentation, see:
      #
      # * http://guides.rubyonrails.org/active_record_validations.html
      #
      # This mixin method provides support for an alternative coding style to
      # method #adds_errors_to?, by generating an Errors collection internally
      # rather than modifying one passed by the caller. It is less efficient
      # than calling #adds_errors_to? if you have an existing errors collection
      # already constructed, but otherwise follows a cleaner design pattern.
      #
      # See #adds_errors_to? examples first, then compare the idiom shown
      # there:
      #
      #     return if model.adds_errors_to?( context.response.errors )
      #
      # ...with the idiomatic use of this method:
      #
      #     context.response.add_errors( model.platform_errors )
      #     return if context.response.halt_processing?
      #
      # It is a little more verbose and in this example will run a little
      # slower due to the construction of the internal Hoodoo::Errors
      # instance followed by the addition to the +context.response+
      # collection, but you may prefer the conceptually cleaner approach.
      # You can lean on the return value of #add_errors and end up back at
      # one line of (very slightly less obvious) code, too:
      #
      #     return if context.response.add_errors( model.platform_errors )
      #
      def platform_errors
        collection = Hoodoo::Errors.new
        self.adds_errors_to?( collection )

        return collection
      end

    end
  end
end
