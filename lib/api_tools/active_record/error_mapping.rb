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

module ApiTools

  # Support mixins for models subclassed from ActiveRecord::Base. See:
  #
  # * http://guides.rubyonrails.org/active_record_basics.html
  #
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # a mapping between ActiveRecord validation errors and platform errors
    # via ApiTools::ErrorDescriptions and ApiTools::Errors. See individual
    # module methods for examples, along with:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module ErrorMapping

      # Validate the model instance and add mapped-to-platform errors to a
      # given context's response object, if any validation errors occur. See:
      #
      # * http://guides.rubyonrails.org/active_record_validations.html
      #
      # +collection+:: An ApiTools::Errors instance, typically obtained
      #                from the ApiTools::ServiceContext instance passed to
      #                a service implementation in calls like
      #                ApiTools::ServiceImplementation#list or
      #                ApiTools::ServiceImplementation#show, via
      #                +context.response.errors+
      #                (i.e. ApiTools::ServiceContext#response /
      #                ApiTools::ServiceResponse#errors). The collection you
      #                pass is updated if there are any errors recorded in
      #                the model, by adding equivalent structured errors to
      #                the collection.
      #
      # +validate+::   Optional, defaults to +true+; the model's +#valid?+
      #                method will be called for you and its errors examined.
      #                If you don't want to call +#valid?+ for any reason,
      #                pass +false+ here.
      #
      # For example, given this model:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include ApiTools::ActiveRecord::ErrorMapping
      #       # ...
      #     end
      #
      # ...then a service's #create method could do something like:
      #
      #     def create( context )
      #
      #       # Validate inbound creation data by e.g. schema through the
      #       # presenter layer - ApiTools::Presenters::Base and
      #       # ApiTools::Presenters::Base - then...
      #
      #       model             = SomeModel.new
      #       model.parameter_1 = 'something based on inbound creation data'
      #
      #       # ...etc., setting other parameters, then have the model run
      #       # its own ActiveRecord-level validations, adding any errors
      #       # it detects to the 'context.response' errors collection.
      #
      #       model.add_errors_to( context.response.errors )
      #       return if context.response.halt_processing?
      #
      #       # At this point 'model.valid?' should be 'true', so we can use
      #       # the throw-exception '#save!' and rely on the middleware's
      #       # exception handler to catch what will be an unexpected failure.
      #
      #       model.save!
      #
      #       # ...then set 'context.response' data appropriately.
      #
      #     end
      #
      # The method returns the +collection+ value given as a parameter. This
      # may be useful for some alternative usage patterns not shown in the
      # example above.
      #
      def add_errors_to( collection, validate = true )
        self.valid? if validate

        self.errors.messages.each_pair do | attribute_name, message_array |
          column = self.class.columns_hash[ attribute_name.to_s ]
          next if column.nil?

          attribute_type = attribute_type_of(attribute_name, column)

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
          end
        end

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

        if self.class.validators_on( attribute_name ).select{ |v| v.instance_of?( UuidValidator ) }.any?
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
