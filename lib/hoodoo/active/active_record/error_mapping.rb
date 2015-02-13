########################################################################
# File::    error_mapping.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing a mapping between API level errors and model
#           validation errors.
# ----------------------------------------------------------------------
#           17-Nov-2014 (ADH): Created.
########################################################################

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
    # Hoodoo::Services::Middleware::Endpoint::AugmentedBase.
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
      # This makes the idiomatic example for "check errors in the model,
      # map them to platform errors in my service's response and return the
      # result" very simple, at the expense of modifying the passed-in
      # error collection contents (mutating a parameter is a risky pattern).
      # For an alternative pattern which avoids this, see #platform_errors.
      #
      # Otherwise, given this example model:
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
      #       # ...etc., setting other parameters, then have the model run
      #       # its own ActiveRecord-level validations, adding any errors it
      #       # detects to the 'context.response' errors collection and exit
      #       # if there were any added, all in a single line:
      #
      #       return if model.adds_errors_to?( context.response.errors )
      #
      #       # At this point 'model.valid?' must be 'true', so we can use
      #       # the throw-exception '#save!' and rely on the middleware's
      #       # exception handler to catch unexpected ActiveRecord failures.
      #
      #       model.save!
      #
      #       # ...then set 'context.response' data appropriately.
      #
      #     end
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
      # +validate+::   Optional, defaults to +true+; the model's +#valid?+
      #                method will be called for you and its errors examined.
      #                If you don't want to call +#valid?+ for any reason,
      #                pass +false+ here. Only any errors already reported
      #                by ActiveModel::Validations#errors will be mapped.
      #                See http://api.rubyonrails.org/classes/ActiveModel/Validations.html#method-i-errors
      #                for more information.
      #
      def adds_errors_to?( collection, validate = true )
        self.valid? if validate

        added = false

        self.errors.messages.each_pair do | attribute_name, message_array |
          column = self.class.columns_hash[ attribute_name.to_s ]
          next if column.nil?

          attribute_type = attribute_type_of( attribute_name, column )

          message_array.each do | message |
            error_code = case message
              when 'has already been taken'
                'generic.invalid_duplication'
              else
                attribute_type.to_s == 'text' ? 'generic.invalid_string' : "generic.invalid_#{ attribute_type }"
            end

            unless collection.descriptions.recognised?( error_code )
              error_code = 'generic.invalid_parameters'
            end

            collection.add_error(
              error_code,
              :message   => message,
              :reference => { :field_name => attribute_name }
            )

            added = true
          end
        end

        return added
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
      # collection, but you may prefer the conceptually cleaner code.
      #
      # +validate+:: Optional, defaults to +true+; same meaning as the same
      #              name parameter in #adds_errors_to?.
      #
      def platform_errors( validate = true )
        collection = Hoodoo::Errors.new
        self.adds_errors_to?( collection, validate )

        return collection
      end

    private

      # Provides a string description for an attribute. UUIDs are detected
      # by checking if the attribute uses the UuidValidator. If the attribute
      # is not a uuid it falls back to a simple type check.
      #
      # +attribute_name+:: The string name of the attribute.
      #
      # +column+::         The attribute's column
      #
      def attribute_type_of( attribute_name, column )

        if self.class.validators_on( attribute_name ).select{ | v | v.instance_of?( UuidValidator ) }.any?
          # Considered a UUID since it uses the UUID validator
          return 'uuid'
        end

        if column.respond_to?( :array ) && column.array
          'array'
        else
          column.type
        end

      end
    end
  end
end
