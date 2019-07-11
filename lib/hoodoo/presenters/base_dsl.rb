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
      # +options+:: Optional +Hash+ of options, e.g. <tt>:required => true</tt>
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
      # are undefined unless the +:type+ option is specified (see below).
      #
      # When an array uses <tt>:required => true</tt>, this only says that at
      # least an empty array must be present, nothing more. If the array uses
      # a block with fields that themselves are required, then this is only
      # checked for if the array contains one or more entries (and is checked
      # for each of those entries).
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      # &block::    Optional block declaring the fields of each array item
      #
      # Array entries are normally either unvalidated, or describe complex
      # types via a block. For simple fields, pass a :type option to declare
      # that array entries must be of supported types as follows:
      #
      # [:array]
      #   Hoodoo::Presenters::Array (see #array)
      # [:boolean]
      #   Hoodoo::Presenters::Boolean (see #boolean)
      # [:date]
      #   Hoodoo::Presenters::Date (see #date)
      # [:date_time]
      #   Hoodoo::Presenters::DateTime (see #datetime)
      # [:decimal]
      #   Hoodoo::Presenters::Decimal (see #decimal)
      # [:enum]
      #   Hoodoo::Presenters::Enum (see #enum)
      # [:float]
      #   Hoodoo::Presenters::Float (see #float)
      # [:integer]
      #   Hoodoo::Presenters::Integer (see #integer)
      # [:string]
      #   Hoodoo::Presenters::String (see #string)
      # [:tags]
      #   Hoodoo::Presenters::Tags (see #tags)
      # [:text]
      #   Hoodoo::Presenters::Text (see #text)
      # [:uuid]
      #   Hoodoo::Presenters::UUID (see #uuid)
      #
      # Some of these types require additional parameters, such as
      # +:precision+ for Hoodoo::Presenters::Decimal or +:from+ for
      # Hoodoo::Presenters::Enum. For _any_ options that are to apply to the
      # the new Array simple type fields, prefix the option with the string
      # +field_+ - for example, <tt>:field_precision => 2</tt>.
      #
      # It does not make sense to attempt to apply field defaults to simple
      # type array entries via +:field_default+; don't do this.
      #
      # In the case of <tt>:type => :array</tt>, the declaring Array is
      # saying that its entries are themselves individually Arrays. This means
      # that validation will ensure and rendering will assume that each of the
      # parent Array entries are themselves Arrays, but will not validte the
      # child Array contents any further. It is not possible to declare an
      # Array with a child Array that has further children, or has child-level
      # validation; instead you would need to use the block syntax, so that
      # the child Array was associated to some named key in the arising
      # Object/Hash making up each of the parent entries.
      #
      # == Block syntax example
      #
      # Mandatory JSON field "currencies" would lead to an array
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
      # == Simple type syntax without field options
      #
      # An optional Array which consists of simple UUIDs as its entries:
      #
      #     class UUIDCollection < Hoodoo::Presenters::Base
      #       schema do
      #         array :uuids, :type => :uuid
      #       end
      #     end
      #
      #     # E.g.:
      #     #
      #     # {
      #     #   "uuids" => [ "...uuid...", "...uuid...", ... ]
      #     # }
      #
      # Validation of data intended to be rendered through such a schema
      # declaration would make sure that each array entry was UUID-like.
      #
      # == Simple type syntax with field options
      #
      # An optional Array which consists of Decimals with precision 2:
      #
      #     class DecimalCollection < Hoodoo::Presenters::Base
      #       schema do
      #         array :numbers, :type => :decimal, :field_precision => 2
      #       end
      #     end
      #
      #     # E.g.:
      #     #
      #     # {
      #     #   "numbers" => [ BigDecimal.new( '2.2511' ) ]
      #     # }
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
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      # &block::    Optional block declaring the fields making up the nested
      #             hash
      #
      # == Block-based complex type examples
      #
      # === Example 1
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
      # === Example 2
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
      # == Simple types
      #
      # As with #array, simple types can be declared for Hash key values by
      # passing a +:type+ option to Hoodoo::Presenters::Hash#key or
      # Hoodoo::Presenters::Hash#keys. See the #array documentation for a list
      # of permitted types.
      #
      # For individual specific keys in Hoodoo::Presenters::Hash#key, it
      # _does_ make sense sometimes to specify field defaults using either a
      # +:default+ or +:field_default+ key (they are synonyms). For arbitrary
      # keys via Hoodoo::Presenters::Hash#keys the situation is the same as
      # with array entries and it does _not_ make sense to specify field
      # defaults.
      #
      # === Simple type example
      #
      #     class Person < Hoodoo::Presenters::Base
      #       schema do
      #         hash :name do
      #           key :first, :type => :text
      #           key :last,  :type => :text
      #         end
      #
      #         hash :address do
      #           keys :type => :text
      #         end
      #
      #         hash :identifiers, :required => true do
      #           keys :length => 8, :type => :string, :field_length => 32
      #         end
      #       end
      #     end
      #
      # The optional Hash called +name+ has two optional keys which must be
      # called +first+ or +last+ and have values that conform to
      # Hoodoo::Presenters::Text.
      #
      # The optional Hash called +address+ has arbitrarily named unbounded
      # length keys which where present must conform to
      # Hoodoo::Presenters::Text.
      #
      # The required Hash called +identifiers+ hash arbitrarily named keys
      # with a maximum length of 8 characters which must have values that
      # conform to Hoodoo::Presenters::String and are each no more than
      # 32 characters long.
      #
      # Therefore the following payload is valid:
      #
      #     data = {
      #       "name" => {
      #         "first" => "Test",
      #         "last" => "Testy"
      #       },
      #       "address" => {
      #         "road" => "1 Test Street",
      #         "city" => "Testville",
      #         "post_code" => "T01 C41"
      #       },
      #       "identifiers" => {
      #         "primary" => "9759c77d188f4bfe85959738dc6f8505",
      #         "postgres" => "1442"
      #       }
      #     }
      #
      #     Person.validate( data )
      #     # => []
      #
      # The following example contains numerous mistakes:
      #
      #     data = {
      #       "name" => {
      #         "first" => "Test",
      #         "surname" => "Testy" # Invalid key name
      #       },
      #       "address" => {
      #         "road" => "1 Test Street",
      #         "city" => "Testville",
      #         "zip" => 90421 # Integer, not Text
      #       },
      #       "identifiers" => {
      #         "primary" => "9759c77d188f4bfe85959738dc6f8505_441", # Value too long
      #         "postgresql" => "1442" # Key name too long
      #       }
      #     }
      #
      #     Person.validate( data )
      #     # => [{"code"=>"generic.invalid_hash",
      #     #      "message"=>"Field `name` is an invalid hash due to unrecognised keys `surname`",
      #     #      "reference"=>"name"},
      #     #     {"code"=>"generic.invalid_string",
      #     #      "message"=>"Field `address.zip` is an invalid string",
      #     #      "reference"=>"address.zip"},
      #     #     {"code"=>"generic.invalid_string",
      #     #      "message"=>"Field `identifiers.primary` is longer than maximum length `32`",
      #     #      "reference"=>"identifiers.primary"},
      #     #     {"code"=>"generic.invalid_string",
      #     #      "message"=>"Field `identifiers.postgresql` is longer than maximum length `8`",
      #     #      "reference"=>"identifiers.postgresql"}]
      #
      def hash( name, options = {}, &block )
        hash = property( name, Hoodoo::Presenters::Hash, options, &block )
        internationalised() if hash.is_internationalised?()
      end

      # Define a JSON integer with the supplied name and options.
      #
      # +name+::   The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def integer( name, options = {} )
        property( name, Hoodoo::Presenters::Integer, options )
      end

      # Define a JSON string with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt> and
      #             mandatory <tt>:length => [max-length-in-chars]</tt>
      #
      def string( name, options = {} )
        property( name, Hoodoo::Presenters::String, options )
      end

      # Define a JSON float with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def float( name, options = {} )
        property( name, Hoodoo::Presenters::Float, options )
      end

      # Define a JSON decimal with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt> and
      #             mandatory <tt>:precision => [decimal-precision-number]</tt>
      #
      def decimal( name, options = {} )
        property( name, Hoodoo::Presenters::Decimal, options )
      end

      # Define a JSON boolean with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def boolean( name, options = {} )
        property( name, Hoodoo::Presenters::Boolean, options )
      end

      # Define a JSON date with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def date( name, options = {} )
        property( name, Hoodoo::Presenters::Date, options )
      end

      # Define a JSON datetime with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def datetime( name, options = {} )
        property( name, Hoodoo::Presenters::DateTime, options )
      end

      # Define a JSON string of unlimited length with the supplied name
      # and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def text( name, options = {} )
        property( name, Hoodoo::Presenters::Text, options )
      end

      # Define a JSON string which can only have a restricted set of exactly
      # matched values, with the supplied name and options.
      #
      # +name+::    The JSON key
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt> and
      #             mandatory
      #             <tt>:from => [array-of-allowed-strings-or-symbols]</tt>
      #
      def enum( name, options = {} )
        property( name, Hoodoo::Presenters::Enum, options )
      end

      # Declares that this Type or Resource has a string field of unlimited
      # length that contains comma-separated tag strings.
      #
      # +field_name+:: Name of the field that will hold the tags.
      # +options+::    Optional options hash. See Hoodoo::Presenters::BaseDSL.
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
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true</tt>
      #
      def property( name, type, options = {}, &block )
        name = name.to_s
        inst = type.new( name, options.merge( { :path => @path + [ name ] } ) )
        inst.instance_eval( &block ) if block_given?

        @properties ||= {}
        @properties[ name ] = inst

        return inst
      end

      # Given a <tt>:type</tt> option key, take the value (which must be a
      # Symbol) and convert it to a class variable for known cases, else
      # raise an exception. Used as a back-end for methods such as
      # Hoodoo::Presenters::Hash#key which support value type validation.
      #
      # +type+:: Required class type expressed as a Symbol (see below).
      #
      # Supported values for the +type+ parameter are:
      #
      # [nil]
      #    Hoodoo::Presenters::Field generic class
      # [:array]
      #   Hoodoo::Presenters::Array
      # [:boolean]
      #   Hoodoo::Presenters::Boolean
      # [:date]
      #   Hoodoo::Presenters::Date
      # [:date_time]
      #   Hoodoo::Presenters::DateTime
      # [:decimal]
      #   Hoodoo::Presenters::Decimal
      # [:enum]
      #   Hoodoo::Presenters::Enum
      # [:float]
      #   Hoodoo::Presenters::Float
      # [:integer]
      #   Hoodoo::Presenters::Integer
      # [:string]
      #   Hoodoo::Presenters::String
      # [:tags]
      #   Hoodoo::Presenters::Tags
      # [:text]
      #   Hoodoo::Presenters::Text
      # [:uuid]
      #   Hoodoo::Presenters::UUID
      # [:hash]
      #   Hoodoo::Presenters::Hash
      # [:object]
      #   Hoodoo::Presenters::Object
      #
      def type_option_to_class( type )
        case type
          when nil
            Hoodoo::Presenters::Field
          when :array
            Hoodoo::Presenters::Array
          when :boolean
            Hoodoo::Presenters::Boolean
          when :date
            Hoodoo::Presenters::Date
          when :date_time
            Hoodoo::Presenters::DateTime
          when :decimal
            Hoodoo::Presenters::Decimal
          when :enum
            Hoodoo::Presenters::Enum
          when :float
            Hoodoo::Presenters::Float
          when :integer
            Hoodoo::Presenters::Integer
          when :string
            Hoodoo::Presenters::String
          when :tags
            Hoodoo::Presenters::Tags
          when :text
            Hoodoo::Presenters::Text
          when :uuid
            Hoodoo::Presenters::UUID
          when :object
            Hoodoo::Presenters::Object
          when :hash
            Hoodoo::Presenters::Hash
          else
            raise "Unsupported 'type' option value of '#{ type }' in Hoodoo::Presenters::BaseDSL"
        end
      end

      # Given a Hash with keys as Symbols or Strings prefixed by the string
      # "field_", return a Hash with those items kept but keys renamed without
      # that "field_" prefix and with all other items removed. The keys in the
      # returned Hash are all coerced to Symbols regardless of input class.
      #
      # +options+:: Hash from which to extract field-specific data.
      #
      def extract_field_prefix_options_from( options )
        options.inject( {} ) do | hash, key_value_pair_array |
          key = key_value_pair_array[ 0 ].to_s

          if key.start_with?( 'field_' )
            hash[ key.sub( /^field_/, '' ).to_sym ] = key_value_pair_array[ 1 ]
          end

          hash
        end
      end

    end
  end
end
