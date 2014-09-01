module ApiTools
  module Presenters
    # A class intended as base functionality for presenter layers in sinatra services. 
    # Although Parsing and rendering of JSON is left to the extender, `BasePresenter` 
    # provides a rich DSL for JSON schema definition and validation.
    class BasePresenter

      class << self; attr_accessor :schema end

      def self.schema(&block)
        @schema = ApiTools::Presenters::Object.new
        @schema.instance_eval &block
      end

      def self.validate(data)
        @schema.validate(data)
      end

      def self.get_schema
        @schema
      end
    end
  end
end