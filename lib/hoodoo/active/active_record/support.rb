########################################################################
# File::    support.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: This file includes a support class that is basically a
#           public, independent expression of a series of specialised
#           methods that would otherwise have been private, were it not
#           for them being called by mixin code. See
#           Hoodoo::ActiveRecord::Support documentation for details.
# ----------------------------------------------------------------------
#           14-Jul-2015 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Most of the ActiveRecord support code provides mixins with
    # a public API. That public interface makes it obvious what
    # the mixin's defined method names will be, helping to avoid
    # collisions/shadowing. Sometimes, those methods want to share
    # code but private methods don't work well in that context -
    # their names could unwittingly collide with names in the
    # including class, written by an author not aware of those
    # essentially hidden but vital interfaces.
    #
    # This is a support class specifically designed to solve this
    # issue. It's really a public, independent expression of a
    # series of specialised methods that would otherwise have
    # normally been private.
    #
    # Although this code forms part of the Hoodoo public API, its
    # unusual status means that you should not really call any of
    # these methods unless you're prepared to track unexpected
    # API changes in them in future and update your calling code.
    #
    class Support

      # Returns a (newly generated) Hash of search keys mapping to helper Procs
      # which are in the same format as would be passed to
      # Hoodoo::ActiveRecord::Finder::ClassMethods#search_with or
      # Hoodoo::ActiveRecord::Finder::ClassMethods#filter_with, describing the
      # default framework search parameters. The middleware defines keys, but
      # each ORM adapter module must specify how those keys actually get used
      # to search inside supported database engines.
      #
      def self.framework_search_and_filter_data

        # The middleware includes framework-level mappings between URI query
        # string search keys and data validators and processors which convert
        # types where necessary. For example, 'created_at' must be given a
        # valid ISO 8601 subset string and a parsed DateTime will end up in
        # the parsed search hash.
        #
        # Services opt out of framework-level searching at an interface level
        # which means the Finder code herein, under normal flow, will never
        # be asked to process something the interface omits. There is thus no
        # need to try and break encapsulation and come up with a way to read
        # the service interface's omissions. Instead, map everything.
        #
        # This could actually be useful if someone manually drives the #list
        # mechanism with hand-constructed search or filter data that quite
        # intentionally includes framework level parameters even if their own
        # service interface for some reason opts out of allowing them to be
        # exposed to API callers.
        #
        # Note that the #search_with / #filter_with DSL declaration in an
        # appropriately extended model can be used to override the default
        # values wired in below, because the defaults are established by
        # design _before_ the model declarations are processed.
        #
        mapping = {
          'created_after'  => Hoodoo::ActiveRecord::Finder::SearchHelper.cs_gt( :created_at ),
          'created_before' => Hoodoo::ActiveRecord::Finder::SearchHelper.cs_lt( :created_at ),
          'created_by'     => Hoodoo::ActiveRecord::Finder::SearchHelper.cs_match( :created_by )
        }

        if mapping.keys.length != ( mapping.keys | Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA.keys ).length
          raise 'Hoodoo::ActiveRecord::Support#framework_search_and_filter_data: Mismatch between internal mapping and Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA'
        end

        return mapping
      end

      # Takes a Hash of possibly-non-String keys and with +nil+ values or
      # Proc instances appropriate for
      # Hoodoo::ActiveRecord::Finder::ClassMethods#search_with /
      # Hoodoo::ActiveRecord::Finder::ClassMethods#filter_with. Returns a
      # similar Hash with all-String keys and a Proc for every value.
      #
      # +hash+:: Hash Symbol or String keys and Proc instance or +nil+
      #          values.
      #
      def self.process_to_map( hash )
        map = Hoodoo::Utilities.stringify( hash )

        map.each do | attr, proc_or_nil |
          if proc_or_nil.nil?
            map[ attr ] = Hoodoo::ActiveRecord::Finder::SearchHelper.cs_match( attr )
          end
        end

        return map
      end

      # Given an ActiveRecord class and Hoodoo request context, work out which
      # Hoodoo support modules are included within this class and call base
      # methods to provide a fully specified basic query chain obeying all the
      # necessary aspects of the ActiveRecord model class and the request.
      #
      # Each of the following are called if the owning module is included:
      #
      # * Hoodoo::ActiveRecord::Secure#secure
      # * Hoodoo::ActiveRecord::Translated#translated
      # * Hoodoo::ActiveRecord::Dated#dated (if "dating_enabled?" is +true+)
      # * Hoodoo::ActiveRecord::ManuallyDated#manually_dated
      #   (if "manual_dating_enabled?" is +true+)
      #
      # +klass+::   The ActiveRecord::Base subclass _class_ (not instance)
      #             which is making the call here. This is the entity which is
      #             checked for module inclusions to determine how the query
      #             chain should be assembled.
      #
      # +context+:: Hoodoo::Services::Context instance describing a call
      #             context. This is typically a value passed to one of
      #             the Hoodoo::Services::Implementation instance methods
      #             that a resource subclass implements.
      #
      # Returns an ActiveRecord::Relation instance which is anything from a
      # generic anonymous scope, all the way through to a secured, translated,
      # backdated scope for use with subsequent query refinements.
      #
      def self.full_scope_for( klass, context )
        prevailing_scope = klass.all() # "Model.all" -> returns anonymous scope

        # Due to the mechanism used, dating scope must be done first or the
        # rest of the query may be invalid.
        #
        if klass.include?( Hoodoo::ActiveRecord::Dated ) && klass.dating_enabled?()
          prevailing_scope = prevailing_scope.dated( context )
        end

        if klass.include?( Hoodoo::ActiveRecord::ManuallyDated ) && klass.manual_dating_enabled?()
          prevailing_scope = prevailing_scope.manually_dated( context )
        end

        return self.add_undated_scope_to( prevailing_scope, klass, context )
      end

      # Back-end of sorts for ::full_scope_for. Given a base scope (e.g.
      # '<tt>Model.all</tt>'), applies all available appropriate scoping
      # additions included by that model, such as Hoodoo::ActiveRecord::Secure
      # and Hoodoo::ActiveRecord::Translated, _except_ for the dating modules
      # Hoodoo::ActiveRecord::Dated and Hoodoo::ActiveRecord::ManuallyDated.
      #
      # If you wish to use dating as well, call ::full_scope_for instead.
      #
      # +base_scope+:: The ActiveRecord::Relation instance providing the base
      #                scope to which additions will be made.
      #
      # +klass+::      The ActiveRecord::Base subclass _class_ (not instance)
      #                which is making the call here. This is the entity which
      #                is checked for module inclusions to determine how the
      #                query chain should be assembled.
      #
      # +context+::    Hoodoo::Services::Context instance describing a call
      #                context. This is typically a value passed to one of
      #                the Hoodoo::Services::Implementation instance methods
      #                that a resource subclass implements.
      #
      # Returns the given input scope, with additional conditions added for
      # any Hoodoo ActiveRecord extension modules included by the ActiveRecord
      # model class that the scope targets.
      #
      def self.add_undated_scope_to( base_scope, klass, context )
        if klass.include?( Hoodoo::ActiveRecord::Secure )
          base_scope = base_scope.secure( context )
        end

        if klass.include?( Hoodoo::ActiveRecord::Translated )
          base_scope = base_scope.translated( context )
        end

        return base_scope
      end

      # When given an ActiveRecord model instance which may have errors set
      # on it as a result of a prior #validate or #save call, map any found
      # errors from ActiveRecord to a Hoodoo::Errors instance. The mapping is
      # comprehensive; it even checks the data type of errant columns and
      # tries to find a +generic...+ family error to use for mapped result
      # (e.g. +generic.invalid_string+ or +generic.invalid_integer+).
      #
      # Usually, the Hoodoo:ActiveRecord::ErrorMapping mixin is included into
      # an ActiveRecord model directly and this method is therefore not used
      # directly; Hoodoo:ActiveRecord::ErrorMapping.adds_errors_to? or
      # similar is called instead.
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
      # ...then <tt>translate_errors_on( parent )</tt> could return a
      # Hoodoo::Errors collection containing entries such as:
      #
      #     {
      #       "code"      => "generic.invalid_string",
      #       "message    => "is too long (maximum is 5 characters)",
      #       "reference" => "children.some_child_field"
      #     }
      #
      # +model_instance+:: The ActiveRecord model which may have errors set
      #                    as a result of a prior validation failure.
      #
      # +hoodoo_errors+::  Optional Hoodoo::Errors instance. If provided, any
      #                    mapped errors are added onto this existing set. If
      #                    omitted, the method returns a new collection.
      #
      # Returns a new Hoodoo::Errors collection (which may have no errors in
      # it, if the model had not validation errors) or the value given in the
      # +hoodoo_errors+ parameter with zero or more new errors added.
      #
      def self.translate_errors_on( model_instance, hoodoo_errors = nil )
        hoodoo_errors ||= Hoodoo::Errors.new

        if model_instance.errors.any?
          model_instance.errors.messages.each_pair do | attribute_name, message_array |
            attribute_name = attribute_name.to_s

            attribute_type = determine_deep_attribute_type( model_instance, attribute_name )
            attribute_name = 'model instance' if attribute_name == 'base'

            message_array.each do | message |
              error_code = case message
                when 'has already been taken'
                  'generic.invalid_duplication'
                else
                  attribute_type == 'text' ? 'generic.invalid_string' : "generic.invalid_#{ attribute_type }"
              end

              unless hoodoo_errors.descriptions.recognised?( error_code )
                error_code = 'generic.invalid_parameters'
              end

              hoodoo_errors.add_error(
                error_code,
                :message   => message,
                :reference => { :field_name => attribute_name }
              )
            end
          end
        end

        return hoodoo_errors
      end

    private

      # Given an attribute for a given model as a string, return the column
      # type associated with it.
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
      # +model_instance+:: The ActiveRecord model instance to inspect.
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
      def self.determine_deep_attribute_type( model_instance, attribute_path )

        attribute_name  = attribute_path
        target_instance = model_instance

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

      private_class_method( :determine_deep_attribute_type )

    end
  end
end
