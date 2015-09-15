########################################################################
# File::    writer.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing context-aware data writing, allowing service
#           authors to auto-inherit persistence-related features from
#           Hoodoo without changing their code.
# ----------------------------------------------------------------------
#           31-Aug-2015 (ADH): Created.
########################################################################

module Hoodoo

  # Support mixins for models subclassed from ActiveRecord::Base. See:
  #
  # * http://guides.rubyonrails.org/active_record_basics.html
  #
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # a...

    # See individual module methods for examples, along with:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Writer

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Writer
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant class that is including
      #           this module.
      #
      def self.included( model )
        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
        super( model )
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Writer::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Writer::included.
      #
      module ClassMethods

        # A concurrent safe way to take attributes for a given resource
        # and save them within a safety net for protection against the inherit
        # lack of idempotency.
        #
        # Regardless of the level of validation (database, or model validations)
        # this will catch those uniqueness constraint errors and ensure that the
        # error is added to +context.response+
        #
        def persist_in( context, attributes: nil, instance: nil )
          # We either get a ready-initialised instance in the 'instance' option or
          # have to bulid one from the 'attributes' option, which takes precedence.

          instance = self.new( attributes ) unless attributes.nil?

          # If this model has an ActiveRecord uniqueness validation, it is still
          # subject to race conditions and should be backed by a database constraint.
          # If this constraint fails, try to re-run model validations just in case it
          # was a race condition case; though of course, it could be that there is
          # *only* a database constraint and no model validation. If there is *only*
          # a model validation, the model is ill-defined and at risk.

          # First just see if we have any problems saving anyway.
          #
          errors_occurred = begin
            :any unless instance.save
          rescue ::ActiveRecord::RecordNotUnique => error
            :duplication
          end

          # If there was a problem, just try adding model-originated mapped errors
          # via the relevant mixin. If there are no errors in context, add one for
          # the invalid duplication case - no uniqueness validations must be on the
          # model.
          #
          unless errors_occurred.nil?
            context.response.add_errors( instance.platform_errors() ) if instance.respond_to?( :platform_errors )

            # We do nothing else. Hoodoo will check for errors on exit and if it
            # sees only duplication-related errors, plus an inbound flag saying
            # that the caller is allowing these, it'll transform the response into
            # a 204. If it sees any other errors, normal processing happens.
            if errors_occurred == :duplication && context.response.halt_processing? == false
              context.response.add_error(
                'generic.invalid_duplication',
                {
                  :message   => 'Cannot create this resource instance due to a uniqueness constraint violation',
                  :reference => { :field_name => 'unknown' }
                }
              )
            end
          end

          return instance
        end

      end
    end
  end
end
