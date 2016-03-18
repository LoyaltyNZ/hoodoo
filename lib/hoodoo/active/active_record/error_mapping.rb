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
      # == Mapping ActiveRecord errors to API errors
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
      # == Associations
      #
      # When a model has associations and nested attributes are accepted for
      # those associations, a validity query on an instance constructed with
      # nested attributes will cause ActiveRecord to traverse all such
      # attributes and aggregate specific errors on the parent object. This
      # is specifically different from +validates_associated+, wherein
      # associations constructed and attached through any means are validated
      # independently, with validation errors independently added to those
      # objects and the parent only gaining a generic "foo is invalid" error.
      #
      # In such cases, the error mapper will attempt to path-traverse the
      # error's column references to determine the association's column type
      # and produce a fully mapped error with a reference to the full path.
      # Service authors are encouraged to use this approach if associations
      # are involved, as it yields the most comprehensive mapped error
      # collection.
      #
      # In the example below, note how the Child model does not need to
      # include Hoodoo error mapping (though it can do so harmlessly if it so
      # wishes) because it is the Parent model that drives the mapping of all
      # the validations aggregated by ActiveRecord into an instance of Parent
      # due to +accepts_nested_attributes_for+.
      #
      # So, given this:
      #
      #     def Parent < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::ErrorMapping
      #
      #       has_many :children
      #       accepts_nested_attributes_for :children
      #     end
      #
      #     def Child < ActiveRecord::Base
      #       belongs_to :parent
      #
      #       # ...then add ActiveRecord validations - e.g.:
      #
      #       validates :some_child_field, :length => { :maximum => 5 }
      #     end
      #
      # ...then if a Parent were to be constructed thus:
      #
      #     parent = Parent.new( {
      #       "parent_field_1" = "foo",
      #       "parent_field_2" = "bar",
      #       "children_attributes" = [
      #         { "some_child_field" = "child_1_foo" },
      #         { "some_child_field" = "child_2_foo" },
      #         # ...
      #       ],
      #       # ...
      #     } )
      #
      # ...then <tt>parent.adds_errors_to?( some_collection )</tt> could lead
      # to +some_collection+ containing errors such as:
      #
      #     {
      #       "code"      => "generic.invalid_string",
      #       "message    => "is too long (maximum is 5 characters)",
      #       "reference" => "children.some_child_field"
      #     }
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

        self.errors.messages.each_pair do | attribute_name, message_array |
          attribute_name = attribute_name.to_s

          attribute_type = nz_co_loyalty_determine_deep_attribute_type( attribute_name )
          attribute_name = 'model instance' if attribute_name == 'base'

          message_array.each do | message |
            error_code = case message
              when 'has already been taken'
                'generic.invalid_duplication'
              else
                attribute_type == 'text' ? 'generic.invalid_string' : "generic.invalid_#{ attribute_type }"
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

    private

      # Given an attribute for this model as a string, return the column type
      # associated with it.
      #
      # The attribute name intended for use here comes from validation and,
      # when there are unsaved associations in an ActiveRecord graph that is
      # being saved, ActiveRecord aggregates child object errors into the
      # target parent being saved with the attribute names using a dot
      # notation to indicate the path of methods to get from one instance to
      # the next. This is resolved. For example:
      #
      # * <tt>address</tt> would look up the type of a column called
      #   "address" in 'this' model.
      #
      # * <tt>addresses.home</tt> would look up the type of a column called
      #   "home" in whatever is accessed by "model.addresses". If this gives
      #   an array, the first entry in the array is taken for column type
      #   retrieval.
      #
      # This path chasing will be done to an arbitrary depth. If at any point
      # there is a failure to follow the path, the path follower exits and
      # the top-level error is used instead, with a generic unknown column
      # type returned.
      #
      # Parameters:
      #
      # +attribute_path+:: _String_ attribute path. Not a Symbol or Array!
      #
      # Return values are any ActiveRecord column type or these special
      # values:
      #
      # * +unknown+ for any unrecognised attribute name or an attribute name
      #   that is a path (it has one or more "."s in it) but where the path
      #   cannot be followed.
      #
      # * +array+ for columns that appear to respond to the +array+ method.
      #
      # * +uuid+ for columns of any known but non-array type, where there is
      #   a UuidValidator present.
      #
      def nz_co_loyalty_determine_deep_attribute_type( attribute_path )

        attribute_name  = attribute_path
        target_instance = self

        # Descend a path of "foo.bar.baz" dereferencing associations from the
        # field names in the dot-separated path until we're at the lowest leaf
        # object with "baz" as its errant field.

        if attribute_path.include?( '.' )

          leaf_instance = target_instance
          leaf_field    = attribute_path

          fields        =  attribute_path.split( '.' )
          leaf_field    = fields.pop() # (remove final entry - the leaf object's errant field)
          reached_field = nil

          fields.each do | field |
            object_at_field = leaf_instance.send( field ) if   leaf_instance.respond_to?(  field )
            object_at_field = object_at_field.first       if object_at_field.respond_to?( :first )

            break if object_at_field.nil?

            leaf_instance = object_at_field
            reached_field = field
          end

          if reached_field == fields.last
            attribute_name  = leaf_field
            target_instance = leaf_instance
          end
        end

        column = target_instance.class.columns_hash[ attribute_name ]

        attribute_type = if column.nil?
          'unknown'
        elsif column.respond_to?( :array ) && column.array
          'array'
        elsif target_instance.class.validators_on( attribute_name ).any? { | v |
            v.instance_of?( UuidValidator )
          } # Considered a UUID since it uses the UUID validator
          'uuid'
        else
          column.type.to_s()
        end

        return attribute_type
      end

    end
  end
end
