module ApiTools
  module Presenters
    # A class intended as base functionality for presenter layers in sinatra services.
    # Although Parsing and rendering of JSON is left to the extender, `BasePresenter`
    # provides a rich DSL for JSON schema definition and validation.
    class BasePresenter

      # Define the JSON schema for validation
      def self.schema(&block)
        @schema = ApiTools::Presenters::Object.new
        @schema.instance_eval &block
      end

      # Validate the given parsed JSON data and return validation/schema structure errors
      # if any.
      def self.validate(data)
        @schema.validate(data)
      end

      def self.parse(data)
        target = @schema.parse(data, {})
      end

      def self.render(data)
        target = {}
        @schema.render(data, target)
        target
      end

      # Return the schema graph.
      def self.get_schema
        @schema
      end
    end
  end
end