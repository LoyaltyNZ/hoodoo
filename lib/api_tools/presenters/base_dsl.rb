########################################################################
# File::    base_dsl.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Implement a DSL used to define a schema for data rendering
#           and validation.
# ----------------------------------------------------------------------
#           02-Dec-2014 (ADH): Merge of DocumentedDSL code into BaseDSL.
########################################################################

module ApiTools
  module Presenters

    # A mixin to be used by any presenter that wants to support the
    # ApiTools::Presenters family of schema DSL methods. See e.g.
    # ApiTools::Presenters::Base. Mixed in by e.g.
    # ApiTools::Presenters::Object so that an instance can nest
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
      # which had the same fields as ApiTools::Data::Types::Currency along with
      # an up-to-32 character string with field name "notes", that field also
      # being required. Whether or not the fields of the referenced Currency
      # type are needed is up to the definition of that type. See #type for
      # more information.
      #
      #     class Wealthy < ApiTools::Presenters::Object
      #       object :currencies, :required => true do
      #         type :Currency
      #         string :notes, :required => true, :length => 32
      #       end
      #     end
      #
      def object( name, options = {}, &block )
        raise ArgumentError.new('ApiTools::Presenters::Object must have block') unless block_given?

        obj = property( name, ApiTools::Presenters::Object, options, &block )
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
      # ApiTools::Data::Types::Currency along with an up-to-32 character string
      # with field name "notes", that field also being required. Whether or not
      # the fields of the referenced Currency type are needed is up to the
      # definition of that type. See #type for more information.
      #
      #     class VeryWealthy < ApiTools::Presenters::Object
      #       array :currencies, :required => true do
      #         type :Currency
      #         string :notes, :required => true, :length => 32
      #       end
      #     end
      #
      def array( name, options = {}, &block )
        ary = property( name, ApiTools::Presenters::Array, options, &block )
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
      # Example 1 - a Hash where keys must be <= 16 characters long and values
      #             must match the ApiTools::Data::Types::Currency type.
      #
      #     class CurrencyHash < ApiTools::Presenters::Object
      #       hash :currencies do
      #         keys :length => 16 do
      #           type :Currency
      #         end
      #       end
      #     end
      #
      # See ApiTools::Presenters::Hash#keys for more information and examples.
      #
      # Example 2 - a Hash where keys must be 'one' or 'two', each with a
      #             value matching the given schema.
      #
      #     class AltCurrencyHash < ApiTools::Presenters::Object
      #       hash :currencies do
      #         key :one do
      #           type :Currency
      #         end
      #
      #         key :two do
      #           text :title
      #           text :description
      #         end
      #       end
      #     end
      #
      # See ApiTools::Presenters::Hash#key for more information and examples.
      #
      def hash( name, options = {}, &block )
        hash = property( name, ApiTools::Presenters::Hash, options, &block )
        internationalised() if hash.is_internationalised?()
      end

      # Define a JSON integer with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def integer(name, options = {})
        property(name, ApiTools::Presenters::Integer, options)
      end

      # Define a JSON string with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 10
      def string(name, options = {})
        property(name, ApiTools::Presenters::String, options)
      end

      # Define a JSON float with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def float(name, options = {})
        property(name, ApiTools::Presenters::Float, options)
      end

      # Define a JSON decimal with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :precision => 10
      def decimal(name, options = {})
        property(name, ApiTools::Presenters::Decimal, options)
      end

      # Define a JSON boolean with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def boolean(name, options = {})
        property(name, ApiTools::Presenters::Boolean, options)
      end

      # Define a JSON date with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def date(name, options = {})
        property(name, ApiTools::Presenters::Date, options)
      end

      # Define a JSON datetime with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def datetime(name, options = {})
        property(name, ApiTools::Presenters::DateTime, options)
      end

      # Define a JSON string of unlimited length with the supplied name
      # and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def text(name, options = {})
        property(name, ApiTools::Presenters::Text, options)
      end

      # Define a JSON string which can only have a restricted set of exactly
      # matched values, with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true and mandatory
      #             :from => [array-of-allowed-strings-or-symbols]
      def enum(name, options = {})
        property(name, ApiTools::Presenters::Enum, options)
      end

      # Declares that this Type or Resource has a string field of unlimited
      # length that contains comma-separated tag strings.
      #
      # +field_name+:: Name of the field that will hold the tags.
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      #
      # Example - a Product resource which supports product tagging:
      #
      #     class Product < ApiTools::Presenters::Object
      #
      #       internationalised
      #
      #       text :name
      #       text :description
      #       string :sku, :length => 64
      #       tags :tags
      #
      #     end
      #
      def tags( field_name, options = nil )
        options ||= {}
        property(field_name, ApiTools::Presenters::Tags, options)
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
      # In addition to standard options from ApiTools::Presenters::BaseDSL,
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
      #     class BasketItem < ApiTools::Presenters::Object
      #
      #       integer :quantity, :required => true
      #       uuid :product_id, :resource => :Product
      #
      #     end
      #
      def uuid( field_name, options = nil )
        options ||= {}
        property(field_name, ApiTools::Presenters::UUID, options)
      end

      # Declare that a nested type of a given name is included at this point.
      # This is only normally done within an +array+ or +object+ declaration.
      # The fields of the given named type are considered to be defined inline
      # at the point of declaration - essentially, it's macro expansion.
      #
      # +type_name+:: Name of the type to nest as a symbol, e.g. +:BasketItem+.
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      #
      # It doesn't make sense to mark a +type+ 'field' as +:required+ in the
      # options since the declaration just expands to the contents of the
      # referenced type and it is the definition of that type that determines
      # whether or not its various field(s) are optional or required.
      #
      # Example 1 - a basket includes an array of the type +BasketItems+.
      #
      #     class Basket < ApiTools::Presenters::Object
      #       array :items do
      #         type :BasketItem
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
      #     class Product < ApiTools::Presenters::Object
      #       internationalised
      #       text :name
      #       text :description
      #     end
      #
      #     class BasketItem < ApiTools::Presenters::Object
      #       object :product_data do
      #         type :Product
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
      # you have, say, a Resource defined entirely in terms of something reused
      # elsewhere as a Type. This is the case for a Currency - for example:
      #
      #     type :Currency do
      #       string :curency_code, :required => true, :length => 8
      #       string :symbol, :length => 16
      #       integer :multiplier, :default => 100
      #       array :qualifiers do
      #         string :qualifier, :length => 32
      #       end
      #     end
      #
      #     resource :Currency do
      #       type :Currency
      #     end
      #
      # This means that the *Resource* of +Currency+ has exactly the same
      # fields as the *Type* of Currency. The Resource could define other
      # fields too, though this would be risky as the Type might gain
      # same-named fields in future, leading to undefined behaviour. At such a
      # time, a degree of cut-and-paste and removing the +type+ call from the
      # Resource definition would be necessary.
      #
      def type( type_name, options = nil )
        options ||= {}

        begin
          klass = ApiTools::Data::Types.const_get( type_name )
        rescue
          raise "DocumentedObject#type: Unrecognised type name '#{type_name}'"
        end

        self.instance_exec( &klass.get_schema_definition() )
      end

      # Declare that a resource of a given name is included at this point. This
      # is only normally done within the description of the schema  for an
      # interface. The fields of the given named resource are considered to be
      # defined inline at the point of declaration - essentially, it's macro
      # expansion.
      #
      # +resource_name+:: Name of the resource as a symbol, e.g. +:Purchase+.
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      #
      # It doesn't make sense to mark a +resource+ 'field' as +:required+ in the
      # options since the declaration just expands to the contents of the
      # referenced resource and it is the definition of that resource that
      # determines whether or not its various field(s) are optional or required.
      #
      # Example - an iterface takes an +Outlet+ resource in its create action.
      #     class Outlet < ApiTools::Presenters::Base
      #       schema do
      #         internationalised
      #
      #         text :name
      #         uuid :participant_id, :resource => :Participant, :required => true
      #         uuid :calculator_id,  :resource => :Calculator
      #       end
      #     end
      #
      #     class OutletInterface < ApiTools::ServiceInterface
      #       to_create do
      #         resource :Outlet
      #       end
      #     end
      #
      #
      def resource( resource_name, options = nil )
        options ||= {}

        begin
          klass = ApiTools::Data::Resources.const_get( resource_name )
        rescue
          raise "DocumentedObject#resource: Unrecognised resource name '#{resource_name}'"
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
      # +options+:: Optional options hash. No option keys/values defined yet.
      #
      # Example - a Member resource with internationalised fields such as
      # the member's name:
      #
      #     class Member < ApiTools::Presenters::Object
      #
      #       # Say that Member will contain at least one field that holds
      #       # human readable data, causing the Member to be subject to
      #       # internationalisation rules.
      #
      #       internationalised
      #
      #       # Declare fields as normal, for example...
      #
      #       text :name
      #
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
