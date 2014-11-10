########################################################################
# File::    documented_dsl.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Presenters::BaseDSL extension mixin used to
#           allow a class to describe a well defined, documented Type
#           or Resource which may refer to another documented Type.
#           Such classes can then be used for JSON validation. Include
#           ApiTools::Presenters::BaseDSL first, then this module.
# ----------------------------------------------------------------------
#           29-Sep-2014 (ADH): Split out from +documented_object.rb+.
########################################################################

module ApiTools
  module Data

    # Analogous to ApiTools::Presenters::BaseDSL, but holds the documented data
    # type and resource DSL extensions only. Same-named methods herein override
    # those in ApiTools::Presenters::BaseDSL.
    #
    # Excellent worked examples that cover a significant swathe of both the
    # base DSL and the extensions defined here can be found in the
    # _implementations_ of the following:
    #
    # * ApiTools::Data::Types::Basket
    # * ApiTools::Data::Resources::Purchase
    #
    module DocumentedDSL

      # As ApiTools::Presenters::BaseDSL#object but with the extended DSL in
      # ApiTools::Data::DocumentedDSL available to the block.
      #
      # +name+:: The JSON key
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      # &block:: Block declaring the fields making up the nested object
      #
      # Example - mandatory JSON field "currencies" would lead to an object
      # which had the same fields as ApiTools::Data::Types::Currency along with
      # an up-to-32 character string with field name "notes", that field also
      # being required. Whether or not the fields of the referenced Currency
      # type are needed is up to the definition of that type. See #type for
      # more information.
      #
      #     class WealthyMember < ApiTools::Data::DocumentedObject
      #       object :currencies, :required => true do
      #         type :Currency
      #         string :notes, :required => true, :length => 32
      #       end
      #     end
      #
      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Data::DocumentedDSL#object must have block') unless block_given?

        obj = property(name, ApiTools::Data::DocumentedObject, options, &block)
        internationalised() if obj.is_internationalised?()
      end

      # As ApiTools::Presenters::BaseDSL#array but with the extended DSL in
      # ApiTools::Data::DocumentedDSL available to the block.
      #
      # +name+:: The JSON key
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      # &block:: Optional block declaring the fields of each array item
      #
      # Example - mandatory JSON field "currencies" would lead to an array
      # where each array entry contains the fields defined by
      # ApiTools::Data::Types::Currency along with an up-to-32 character string
      # with field name "notes", that field also being required. Whether or not
      # the fields of the referenced Currency type are needed is up to the
      # definition of that type. See #type for more information.
      #
      #     class VeryWealthyMember < ApiTools::Data::DocumentedObject
      #       array :currencies, :required => true do
      #         type :Currency
      #         string :notes, :required => true, :length => 32
      #       end
      #     end
      #
      def array(name, options = {}, &block)
        ary = property(name, ApiTools::Data::DocumentedArray, options, &block)
        internationalised() if ary.is_internationalised?()
      end

      # As ApiTools::Presenters::BaseDSL#hash but with the extended DSL in
      # ApiTools::Data::DocumentedDSL available to the block.
      #
      # +name+:: The JSON key
      # +options+:: Optional options hash. See ApiTools::Presenters::BaseDSL.
      # &block:: Optional block declaring the characteristics of the Hash.
      #
      # Example - a Hash where keys must be <= 16 characters long and values
      #           must match the ApiTools::Data::Types::Currency type.
      #
      #     class CurrencyHash < ApiTools::Data::DocumentedObject
      #       hash :currencies do
      #         keys :length => 16 do
      #           type :Currency
      #         end
      #       end
      #     end
      #
      def hash(name, options = {}, &block)
        hash = property(name, ApiTools::Data::DocumentedHash, options, &block)
        internationalised() if hash.is_internationalised?()
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
      #     class Member < ApiTools::Data::DocumentedObject
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
      #     class Basket < ApiTools::Data::DocumentedObject
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
      #     class Product < ApiTools::Data::DocumentedObject
      #       internationalised
      #       text :name
      #       text :description
      #     end
      #
      #     class BasketItem < ApiTools::Data::DocumentedObject
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

        self.instance_exec( &klass.schema_definition() )
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
      #     class Outlet < ApiTools::Data::DocumentedPresenter
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

        self.instance_exec( &klass.schema_definition() )
      end

    end
  end
end
