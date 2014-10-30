module ApiTools
  module Presenters

    # A mixin to be used by any presenter that wants to support the
    # ApiTools::Presenters family of schema DSL methods. See e.g.
    # ApiTools::Presenters::BasePresenter. Mixed in by e.g.
    # ApiTools::Presenters::Object so that an instance can nest
    # definitions of fields inside itself using this DSL.
    #
    module BaseDSL

      # Define a JSON object with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block:: Block declaring the fields making up the nested object
      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Presenters::Object must have block') unless block_given?
        property(name, ApiTools::Presenters::Object, options, &block)
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
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # &block:: Optional block declaring the fields of each array item
      def array(name, options = {}, &block)
        property(name, ApiTools::Presenters::Array, options, &block)
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
      #     class BasketItem < ApiTools::Data::DocumentedObject
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

    private

      # Define a JSON property with the supplied name, type and options.
      # Returns the new property instance.
      # Params
      # +name+:: The JSON key
      # +type+:: A +Class+ for validation
      # +options+:: A +Hash+ of options, e.g. :required => true
      def property(name, type, options = {}, &block)
        name = name.to_s
        inst = type.new name, options.merge({:path => @path + [name]})
        inst.instance_eval &block if block_given?
        @properties ||= {}
        @properties[name] = inst
        return inst
      end

    end
  end
end
