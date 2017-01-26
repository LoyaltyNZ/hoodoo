########################################################################
# File::    base_dsl.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Implement a DSL used to define a schema for data rendering
#           and validation.
# ----------------------------------------------------------------------
#           02-Dec-2014 (ADH): Merge of DocumentedDSL code into BaseDSL.
########################################################################

module Hoodoo
  module Presenters

    # A mixin to be used by any presenter that wants to support the
    # Hoodoo::Presenters family of schema DSL methods. See e.g.
    # Hoodoo::Presenters::Base. Mixed in by e.g.
    # Hoodoo::Presenters::Object so that an instance can nest
    # definitions of fields inside itself using this DSL.
    #
    module BaseDSL

      # Define a JSON object with the supplied name and options.
      #
      # +name+::    The JSON key.
      # +options+:: Optional +Hash+ of options, e.g. :required => true
      # &block::    Block declaring the fields making up the nested object
      #
      # Example - mandatory JSON field "currencies" would lead to an object
      # which had the same fields as Hoodoo::Data::Types::Currency along with
      # an up-to-32 character string with field name "notes", that field also
      # being required. Whether or not the fields of the referenced Currency
      # type are needed is up to the definition of that type. See #type for
      # more information.
      #
      #     class Wealthy < Hoodoo::Presenters::Base
      #       schema do
      #         object :currencies, :required => true do
      #           type :Currency
      #           string :notes, :required => true, :length => 32
      #         end
      #       end
      #     end
      #
      def object( name, options = {}, &block )
        raise ArgumentError.new( 'Hoodoo::Presenters::Base#Object must have block' ) unless block_given?

        obj = property( name, Hoodoo::Presenters::Object, options, &block )
        internationalised() if obj.is_internationalised?()
      end

      # Define a JSON array with the supplied name and options. If there is
      # a block provided, then more DSL calls inside the block define how each
      # array entry must look; otherwise array entries are not validated /
      # are undefined.
      #
      # When an array field uses +:required => true+, this only says that at
      # least an empty array must be present, nothing more. If the array uses
      # a block with fields that themselves are required, then this is only
      # checked for if the array contains one or more entries (and is checked
      # for each of those entries).
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block::    Optional block declaring the fields of each array item
      #
      # Example - mandatory JSON field "currencies" would lead to an array
      # where each array entry contains the fields defined by
      # Hoodoo::Data::Types::Currency along with an up-to-32 character string
      # with field name "notes", that field also being required. Whether or not
      # the fields of the referenced Currency type are needed is up to the
      # definition of that type. See #type for more information.
      #
      #     class VeryWealthy < Hoodoo::Presenters::Base
      #       schema do
      #         array :currencies, :required => true do
      #           type :Currency
      #           string :notes, :required => true, :length => 32
      #         end
      #       end
      #     end
      #
      def array( name, options = {}, &block )
        ary = property( name, Hoodoo::Presenters::Array, options, &block )
        internationalised() if ary.is_internationalised?()
      end

      # Define a JSON object with the supplied name and optional constraints
      # on properties (like hash keys) and property values (like hash values)
      # that the object may contain, in abstract terms.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block::    Optional block declaring the fields making up the nested
      #             hash
      #
      # == Example 1
      #
      # A Hash where keys must be <= 16 characters long and values must match
      # a <tt>Hoodoo::Data::Types::Currency</tt> type (with the default
      # Hoodoo::Data::Types namespace use arising from the Symbol passed
      # to the #type method).
      #
      #     class CurrencyHash < Hoodoo::Presenters::Base
      #       schema do
      #         hash :currencies do
      #           keys :length => 16 do
      #             type :Currency
      #           end
      #         end
      #       end
      #     end
      #
      # See Hoodoo::Presenters::Hash#keys for more information and examples.
      #
      # == Example 2
      #
      # A Hash where keys must be 'one' or 'two', each with a value matching
      # the given schema. Here, the example assumes that a subclass of
      # Hoodoo::Presenters::Base has been defined under the name of
      # <tt>SomeNamespace::Types::Currency</tt>, since this is passed as a
      # class reference to the #type method.
      #
      #     class AltCurrencyHash < Hoodoo::Presenters::Base
      #       schema do
      #         hash :currencies do
      #           key :one do
      #             type SomeNamespace::Types::Currency
      #           end
      #
      #           key :two do
      #             text :title
      #             text :description
      #           end
      #         end
      #       end
      #     end
      #
      # See Hoodoo::Presenters::Hash#key for more information and examples.
      #
      # == Limitations
      #
      # The syntax cannot express simple value types. It always describes a
      # nested object. So, the following describes a Hash called +payload+
      # which has arbitrary keys each leading to a nested _object_ with
      # key/value pair where the key is called +some_value+ and the value
      # is an arbitrary length String:
      #
      #     class NotSoSimpleHash < Hoodoo::Presenters::Base
      #       schema do
      #         hash :payload do
      #           keys do
      #             text :some_value
      #           end
      #         end
      #       end
      #     end
      #
      # This is a valid piece of Ruby input data for the above which will
      # render without changes and validate successfully:
      #
      #     data = {
      #       "payload" => {
      #         "any_key_name"     => { "some_value" => "Any string" },
      #         "another_key_name" => { "some_value" => "Another string" },
      #       }
      #     }
      #
      #     NotSoSimpleHash.validate( data )
      #     # => []
      #
      # This is invalid because one of the values is not a String:
      #
      #     data = {
      #       "payload" => {
      #         "any_key_name"     => { "some_value" => "Any string" },
      #         "another_key_name" => { "some_value" => 22 },
      #       }
      #     }
      #
      #     NotSoSimpleHash.validate( data )
      #     # => [{"code"=>"generic.invalid_string",
      #     #      "message"=>"Field `payload.another_key_name.some_value` is an invalid string",
      #     #      "reference"=>"payload.another_key_name.some_value"}]
      #
      # This is invalid because the DSL cannot express a simple String value
      # for the keys:
      #
      #     data = {
      #       "payload" => {
      #         "any_key_name"     => "Any string",
      #         "another_key_name" => "Another string",
      #       }
      #     }
      #
      #     NotSoSimpleHash.validate( data )
      #     # => [{"code"=>"generic.invalid_object",
      #     #      "message"=>"Field `payload.any_key_name` is an invalid object",
      #     #      "reference"=>"payload.any_key_name"},
      #     #     {"code"=>"generic.invalid_object",
      #     #      "message"=>"Field `payload.another_key_name` is an invalid object",
      #     #      "reference"=>"payload.another_key_name"}]
      #
      def hash( name, options = {}, &block )
        hash = property( name, Hoodoo::Presenters::Hash, options, &block )
        internationalised() if hash.is_internationalised?()
      end

      # Define a JSON integer with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def integer( name, options = {} )
        property( name, Hoodoo::Presenters::Integer, options )
      end

      # Define a JSON string with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 10
      #
      def string( name, options = {} )
        property( name, Hoodoo::Presenters::String, options )
      end

      # Define a JSON float with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def float( name, options = {} )
        property( name, Hoodoo::Presenters::Float, options )
      end

      # Define a JSON decimal with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :precision => 10
      #
      def decimal( name, options = {} )
        property( name, Hoodoo::Presenters::Decimal, options )
      end

      # Define a JSON boolean with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def boolean( name, options = {} )
        property( name, Hoodoo::Presenters::Boolean, options )
      end

      # Define a JSON date with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def date( name, options = {} )
        property( name, Hoodoo::Presenters::Date, options )
      end

      # Define a JSON datetime with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def datetime( name, options = {} )
        property( name, Hoodoo::Presenters::DateTime, options )
      end

      # Define a JSON string of unlimited length with the supplied name
      # and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def text( name, options = {} )
        property( name, Hoodoo::Presenters::Text, options )
      end

      # Define a JSON string which can only have a restricted set of exactly
      # matched values, with the supplied name and options.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true and mandatory
      #             :from => [array-of-allowed-strings-or-symbols]
      #
      def enum( name, options = {} )
        property( name, Hoodoo::Presenters::Enum, options )
      end

      # Declares that this Type or Resource has a string field of unlimited
      # length that contains comma-separated tag strings.
      #
      # +field_name+:: Name of the field that will hold the tags.
      # +options+:: Optional options hash. See Hoodoo::Presenters::BaseDSL.
      #
      # Example - a Product resource which supports product tagging:
      #
      #     class Product < Hoodoo::Presenters::Base
      #       schema do
      #         internationalised
      #
      #         text :name
      #         text :description
      #         string :sku, :length => 64
      #         tags :tags
      #       end
      #     end
      #
      def tags( field_name, options = nil )
        options ||= {}
        property( field_name, Hoodoo::Presenters::Tags, options )
      end

      # Declares that this Type or Resource _refers to_ another Resource
      # instance via its UUID. There's no need to declare the presence of the
      # UUID field _for the instance itself_ on all resource definitions as
      # that's implicit; this #uuid method is just for relational information
      # (AKA associations).
      #
      # +field_name+:: Name of the field that will hold the UUID.
      # +options+:: Options hash. See below.
      #
      # In addition to standard options from Hoodoo::Presenters::BaseDSL,
      # extra option keys and values are:
      #
      # +:resource+:: The name of a resource (as a symbol, e.g. +:Product+) that
      #               the UUID should refer to. Implementations _may_ use this
      #               to validate that the resource, where a UUID is provided,
      #               really is for a Product instance and not something else.
      #               Optional.
      #
      # Example - a basket item that refers to an integer quantity of some
      # specific Product resource instance:
      #
      #     class BasketItem < Hoodoo::Presenters::Base
      #       schema do
      #         integer :quantity, :required => true
      #         uuid :product_id, :resource => :Product
      #       end
      #     end
      #
      def uuid( field_name, options = nil )
        options ||= {}
        property(field_name, Hoodoo::Presenters::UUID, options)
      end

      # Declare that a nested type of a given name is included at this point.
      # This is only normally done within an +array+ or +object+ declaration.
      # The fields of the given named type are considered to be defined inline
      # at the point of declaration - essentially, it's macro expansion.
      #
      # +type_info+:: The Hoodoo::Presenters::Base subclass for the Type in
      #               question, e.g. +BasketItem+. The deprecated form of this
      #               interface takes the name of the type to nest as a symbol,
      #               e.g. +:BasketItem+, in which case the Type must be
      #               declared within nested modules Hoodoo::Data::Types.
      #
      # +options+::   Optional options hash. No options currently defined.
      #
      # It doesn't make sense to mark a +type+ 'field' as +:required+ in the
      # options since the declaration just expands to the contents of the
      # referenced type and it is the definition of that type that determines
      # whether or not its various field(s) are optional or required.
      #
      # Example 1 - a basket includes an array of the Type described by class
      # +BasketItem+:
      #
      #     class Basket < Hoodoo::Presenters::Base
      #       schema do
      #         array :items do
      #           type BasketItem
      #         end
      #       end
      #     end
      #
      # A fragment of JSON for a basket might look like this:
      #
      #   {
      #     "items": [
      #       {
      #          // (First BasketItem's fields)
      #       },
      #       {
      #          // (First BasketItem's fields)
      #       },
      #       // etc.
      #     ]
      #   }
      #
      # Example 2 - a basket item refers to a product description by having
      # its fields inline. So suppose we have this:
      #
      #     class Product < Hoodoo::Presenters::Base
      #       schema do
      #         internationalised
      #         text :name
      #         text :description
      #       end
      #     end
      #
      #     class BasketItem < Hoodoo::Presenters::Base
      #       schema do
      #         object :product_data do
      #           type Product
      #         end
      #       end
      #     end
      #
      # ...then this would be a valid BasketItem fragment of JSON:
      #
      #     {
      #       "product_data": {
      #         "name": "Washing powder",
      #         "description": "Washes whiter than white!"
      #       }
      #     }
      #
      # It is also possible to use this mechanism for inline expansions when
      # you have, say, a Resource defined _entirely_ in terms of something
      # reused elsewhere as a Type. For example, suppose the product/basket
      # information from above included information on a Currency that was
      # used for payment. It might reuse a Type; meanwhile we might have a
      # resource for managing Currencies, defined entirely through that Type:
      #
      #     class Currency < Hoodoo::Presenters::Base
      #       schema do
      #         string :curency_code, :required => true, :length => 8
      #         string :symbol, :length => 16
      #         integer :multiplier, :default => 100
      #         array :qualifiers do
      #           string :qualifier, :length => 32
      #         end
      #       end
      #     end
      #
      #     resource :Currency do
      #       schema do
      #         type Currency # Fields are *inline*
      #       end
      #     end
      #
      # This means that the *Resource* of +Currency+ has exactly the same
      # fields as the *Type* of Currency. The Resource could define other
      # fields too, though this would be risky as the Type might gain
      # same-named fields in future, leading to undefined behaviour. At such a
      # time, a degree of cut-and-paste and removing the +type+ call from the
      # Resource definition would probably be wise.
      #
      def type( type_info, options = nil )
        options ||= {}

        if type_info.is_a?( Class ) && type_info < Hoodoo::Presenters::Base
          klass = type_info
        else
          begin
            klass = Hoodoo::Data::Types.const_get( type_info )
          rescue
            raise "Hoodoo::Presenters::Base\#type: Unrecognised type name '#{ type_info }'"
          end
        end

        self.instance_exec( &klass.get_schema_definition() )
      end

      # Declare that a resource of a given name is included at this point.
      # This is only normally done within the description of the schema for an
      # interface. The fields of the given named resource are considered to be
      # defined inline at the point of declaration - essentially, it's macro
      # expansion.
      #
      # +resource_info+:: The Hoodoo::Presenters::Base subclass for the
      #                   Resource in question, e.g. +Product+. The deprecated
      #                   form of this interface takes the name of the type to
      #                   nest as a symbol, e.g. +:Product+, in which case the
      #                   Resource must be declared within nested modules
      #                   Hoodoo::Data::Types.
      #
      # +options+::       Optional options hash. No options currently defined.
      #
      # Example - an iterface takes an +Outlet+ resource in its create action.
      #
      #     class Outlet < Hoodoo::Presenters::Base
      #       schema do
      #         internationalised
      #
      #         text :name
      #         uuid :participant_id, :resource => :Participant, :required => true
      #         uuid :calculator_id,  :resource => :Calculator
      #       end
      #     end
      #
      #     class OutletInterface < Hoodoo::Services::Interface
      #       to_create do
      #         resource Outlet
      #       end
      #     end
      #
      # It doesn't make sense to mark a +resource+ 'field' as +:required+ in
      # the options since the declaration just expands to the contents of the
      # referenced resource and it is the definition of that resource that
      # determines whether or not its various field(s) are optional / required.
      # That is, the following two declarations behave identically:
      #
      #     resource Outlet
      #
      #     resource Outlet, :required => true # Pointless option!
      #
      def resource( resource_info, options = nil )
        options ||= {}

        if resource_info.is_a?( Class ) && resource_info < Hoodoo::Presenters::Base
          klass = resource_info
        else
          begin
            klass = Hoodoo::Data::Resources.const_get( resource_info )
          rescue
            raise "Hoodoo::Presenters::Base\#resource: Unrecognised resource name '#{ resource_info }'"
          end
        end

        self.instance_exec( &klass.get_schema_definition() )
      end

      # Declares that this Type or Resource contains fields which will may
      # carry human-readable data subject to platform interntionalisation
      # rules. A Resource which is internationalised automatically gains a
      # +language+ field (part of the Platform API's Common Fields) used
      # in resource representations. A Type which is internationalised
      # gains nothing until it is cross-referenced by a Resource definion,
      # at which point the cross-referencing resource becomes itself
      # implicitly internationalised (so it "taints" the resource). For
      # cross-referencing, see #type.
      #
      # +options+:: Optional options hash. No options currently defined.
      #
      # Example - a Member resource with internationalised fields such as
      # the member's name:
      #
      #     class Member < Hoodoo::Presenters::Base
      #       schema do
      #
      #         # Say that Member will contain at least one field that holds
      #         # human readable data, causing the Member to be subject to
      #         # internationalisation rules.
      #
      #         internationalised
      #
      #         # Declare fields as normal, for example...
      #
      #         text :name
      #
      #       end
      #     end
      #
      def internationalised( options = nil )
        options ||= {}
        @internationalised = true
      end

      # An enquiry method related to, but not part of the DSL; returns +true+
      # if the schema instance is internationalised, else +false+.
      #
      def is_internationalised?
        !! @internationalised
      end

    private

      # Define a JSON property with the supplied name, type and options.
      # Returns the new property instance.
      #
      # +name+::    The JSON key
      # +type+::    A +Class+ for validation
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def property( name, type, options = {}, &block )
        name = name.to_s
        inst = type.new( name, options.merge( { :path => @path + [ name ] } ) )
        inst.instance_eval( &block ) if block_given?

        @properties ||= {}
        @properties[ name ] = inst

        return inst
      end

    end
  end
end
