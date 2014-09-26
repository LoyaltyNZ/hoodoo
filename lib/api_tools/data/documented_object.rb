########################################################################
# File::    documented_object.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Presenters::Object DSL extension used to allow a
#           class to describe a well defined, documented Type or
#           Resource which may refer to another documented Type. Such
#           classes can then be used for JSON validation.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # Common data definitions and descriptions - describe, through a DSL, the
  # *representations* of Types and Resources documented in the Loyalty Platform
  # API.
  #
  # These descriptions omit common fields like "kind" or "created_at", as those
  # are implicit for any resource. Since resource representations are things
  # returned by services, the definitions are used for automatic validation of
  # service responses, not for validation of data sent in requests. That's done
  # via the DSL available to ApiTools::ServiceInterface subclasses, e.g.
  # ApiTools::ServiceInterface#to_create.
  #
  module Data

    # Extends the schema description DSL provided by
    # ApiTools::Presenters::Object with extra methods which are appropriate
    # for declarations of both Resources and Types described by the Loyalty
    # Platform API documentation.
    #
    class DocumentedObject < ApiTools::Presenters::Object

      # Does this instance state that it requires internationalisation?
      # If so +true+, else +false+.
      #
      def is_internationalised
        @internationalised == true
      end

      # Initialize a DocumentedObject instance with the appropriate name and
      # options; see ApiTools::Presenters::Object.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      #
      def initialize(name = nil, options = {})
        @internationalised = false
        super name, options
      end

      # As ApiTools::Presenters::Object#object but with the extended DSL in
      # ApiTools::Data::DocumentedObject classes.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block:: Block declaring the fields making up the nested object
      #
      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Data::DocumentedObject must have block') unless block_given?
        property(name, ApiTools::Data::DocumentedObject, options, &block)
      end

      # As ApiTools::Presenters::Object#array but with the extended DSL in
      # ApiTools::Data::DocumentedObject / ApiTools::Data::DocumentedArray
      # classes.
      #
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block:: Optional block declaring the fields of each array item
      #
      def array(name, options = {}, &block)
        property(name, ApiTools::Data::DocumentedArray, options, &block)
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

      # Declares that this Type or Resource has a string field of unlimited
      # length that contains comma-separated tag strings.
      #
      # +field_name+:: Name of the field that will hold the tags.
      # +options+:: Optional options hash. No option keys/values defined yet.
      #
      # Example - a Product resource which supports product tagging:
      #
      #     class Product < ApiTools::Data::DocumentedObject
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

        # TODO: Something more advanced than just treating this as a 'text'
        #       field, with no additional validation. From a JSON perspective,
        #       though, there might not be anything else to do.

        property(field_name, ApiTools::Presenters::Text, options)
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
      # In addition to standard options from ApiTools::Presenters::Object,
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
      #     class BasketItem < ApiTools::Data::DocumentedObject
      #
      #       integer :quantity, :required => true
      #       uuid :product_id, :resource => :Product
      #
      #     end
      #
      def uuid( field_name, options = nil )
        options ||= {}
        property(field_name, ApiTools::Data::DocumentedUUID, options)
      end

      # Declare that a nested type of a given name is included at this point.
      # This is only normally done within an +array+ or +object+ declaration.
      # The fields of the given named type are considered to be defined inline
      # at the point of declaration - essentially, it's macro expansion.
      #
      # +type_name+:: Name of the type to nest as a symbol, e.g. +:BasketItem+.
      # +options+:: Optional options hash. See ApiTools::Presenters::Object.
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

        self.instance_exec( &klass.definition() )
      end
    end

  end
end
