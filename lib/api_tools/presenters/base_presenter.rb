module ApiTools
  module Presenters
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