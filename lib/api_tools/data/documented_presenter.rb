########################################################################
# File::    documented_presenter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for predefined Type and Resource definitions
#           that inherit the ApiTools::Presenters::BasePresenter methods
#           for parsing, rendering and validation.
# ----------------------------------------------------------------------
#           26-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # Base class for predefined Type and Resource definitions
    # that inherit the ApiTools::Presenters::BasePresenter methods
    # for parsing, rendering and validation.
    #
    # See the ApiTools::Data::Types and ApiTools::Data::Resources
    # collections of subclasses for more.
    #
    class DocumentedPresenter < ApiTools::Presenters::BasePresenter

      # Define the JSON schema for validation.
      #
      # &block:: Block that makes calls to the DSL defined by
      #          ApiTools::Data::DocumentedObject.
      #
      def self.schema(&block)
        @schema = ApiTools::Data::DocumentedObject.new
        @schema.instance_eval &block
        @schema_definition = block
      end

      # Read back the block that defined the schema.
      #
      def self.schema_definition
        @schema_definition
      end

    end
  end
end
