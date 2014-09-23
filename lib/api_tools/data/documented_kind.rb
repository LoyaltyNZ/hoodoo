module ApiTools
  module Data

    # Documented Platform API Types - common code.
    #
    class DocumentedKind < ApiTools::Data::DocumentedObject

      # Retrieve the block that defines this type's schema. See also protected
      # class method #define, which subclasses call to set that schema.
      #
      def self.definition
        @definition
      end

      # Create an instance of a type with all of its fields defined, ready to
      # be used as a presenter. You can call methods from
      # ApiTools::Presenters::Object on the instance, such as
      # ApiTools::Presenters::Object#validate; or rather more usefully, assign
      # this object instance as the schema to an
      # ApiTools::Presenters::BasePresenter class or subclass then use that
      # higher level interface for parsing, validation and rendering.
      #
      #     ApiTools::Presenters::BasePresenter.schema = SomeTypeClass.new
      #     ApiTools::Presenters::BasePresenter.render( { field: "value" } )
      #
      def initialize
        super
        definition = self.class.definition()
        instance_eval( &definition ) unless definition.nil?
      end

    protected

      # Subclasses call here with a block and define their schema for the
      # type the subclass represents within that block. For example:
      #
      #     class SomeTypeClass < ApiTools::Data::DocumentedKind
      #       define do
      #         text :text_field
      #         string :mandatory, :required => true, :length => 32
      #       end
      #     end
      #
      # Methods available from within the +define+ block are the union of those
      # provided by ApiTools::Data::DocumentedObject and the class from which
      # this inherits, ApiTools::Data::Object.
      #
      # +&block+:: Block that defines the schema for this type.
      #
      def self.define( &block )
        @definition = block
      end
    end
  end
end
