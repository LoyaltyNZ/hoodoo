module ApiTools
  module Presenters

    # Base functionality for JSON validation and presenter (rendering) layers.
    # Subclass this to define a schema against which validation of inbound data
    # or rendering of outbound data can be performed. Call ::schema in the
    # subclass to declare, via the DSL, the shape of the schema.
    #
    class BasePresenter

      # Define the JSON schema for validation.
      #
      # &block:: Block that makes calls to the DSL defined in
      #          ApiTools::Presenters::BaseDSL in order to define the schema.
      #
      def self.schema(&block)
        @schema = ApiTools::Presenters::Object.new
        @schema.instance_eval &block
      end

      # Given JSON data that's been parsed from a String into an equivalent
      # Ruby Hash, with String keys, validate that data against the schema and
      # return an ApiTools::Errors instance. This will contain *zero or more*
      # errors; if zero, there is no problem, else validation failures are
      # described.
      #
      # +data+:: Ruby Hash representation of JSON data that is to be validated
      #          against 'this' schema. Keys must be Strings, not Symbols.
      #
      def self.validate(data)
        @schema.validate(data)
      end

      # Given some data that should conform to the subclass presenter's schema,
      # render it to go from the input Ruby Hash, to an output Ruby Hash which
      # will include default values - if any - present in the schema and will
      # drop input fields not present in that schema. In essence, this takes
      # data which may have been programatically generated and sanitises it to
      # produce valid, with-defaults guaranteed valid output.
      #
      # Any field with a schema giving a default value will only appear should
      # a value for that field be _omitted_ in the input data. If the data
      # provides, for example, an explicit +nil+ value then a corresponding
      # explicit +nil+ will be rendered, regardless of defaults.
      #
      # For belt-and-braces, unless subsequent profiling shows performance
      # issues, callers should call #validate first to self-check their internal
      # data against the schema prior to rendering. That way, coding errors
      # will be discovered immediately, rather than hidden / obscured by the
      # rendered sanitisation.
      #
      # Since rendering top-level +nil+ is not valid JSON, should +nil+ be
      # provided as input, it'll be treated as an empty hash ("+{}+") instead.
      #
      def self.render(data)
        target = {}
        data   = data || {}
        @schema.render(data, target)
        target
      end

      # Return the schema graph.
      #
      def self.get_schema
        @schema
      end
    end
  end
end