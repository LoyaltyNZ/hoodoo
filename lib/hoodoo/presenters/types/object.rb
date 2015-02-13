module Hoodoo
  module Presenters
    # A JSON object schema member
    class Object < Hoodoo::Presenters::Field

      include Hoodoo::Presenters::BaseDSL

      # The properties of this object; a Hash of +Field+ instances keyed by
      # field name.
      #
      attr_accessor :properties

      # Initialize an Object instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name = nil, options = {})
        super name, options

        @properties        = {}
        @internationalised = false
      end

      # Check if data is a valid Object and return a Hoodoo::Errors instance
      # with zero (valid) or more (has validation problems) errors inside.
      #
      # +data+: Data to check (and check nested properties therein). Expected
      #         to be nil (unless field is required) or a Hash.
      #
      # +path+: For internal callers only in theory. The nesting human-readable
      #         path to this "level", as an array. Omitted at the top level.
      #         In :errors => { :foo => { ... } }, validation of ":foo" would
      #         be at path "[ :errors ]". Validation of the contents of the
      #         object at ":foo" would be under "[ :errors, :foo ]".
      #
      def validate(data, path = '')
        errors = super data, path
        return errors if !@required and data.nil? # If there are existing errors, we carry on and validate internally too

        if !data.nil? and !data.is_a? ::Hash
          errors.add_error(
            'generic.invalid_object',
            :message   => "Field `#{ full_path( path ) }` is an invalid object",
            :reference => { :field_name => full_path( path ) }
          )
        end

        @properties.each do |name, property|
          rdata = (data.is_a?(::Hash) and data.has_key?(name)) ? data[name] : nil
          errors.merge!( property.validate(rdata, full_path( path ) ) )
        end

        errors
      end

      # Render inbound data into a target hash according to the schema,
      # applying defaults where defined for fields with no value supplied
      # in the inbound data.
      #
      # +data+:   Inbound data to render.
      #
      # +target+: For internal callers only in theory. The target hash into
      #           which rendering should occur. This may then be merged into
      #           outer level hashes as part of nested items defined in the
      #           schema.
      #
      def render( data, target )

        # In an simple field, e.g. a text field, then whether or not it has
        # a default, should someone give a value of "nil" we expect that field
        # to be rendered in output with the explicitly provided "nil" value.
        # We thus apply the same to objects. A field with an associated object,
        # if rendered with an explicit "nil", renders as just that.
        #
        return super( nil, target ) unless data.is_a?( ::Hash ) # nil or invalid

        have_rendered_something = false

        @properties.each do | name, property |
          name        = name.to_s
          has_key     = data.has_key?( name )
          has_default = property.has_default?()

          next unless has_key || has_default

          have_rendered_something = true
          property.render( has_key ? data[ name ] : property.default, target )
        end

        # If someone passes an empty object for a field and the object schema
        # includes no default values, then the above code would render nothing
        # as no properties have associated keys in the input data, and none of
        # them have default values either. Make sure we render the field for
        # this object with the associated empty object given by the input data
        # in such cases.
        #
        super( {}, target ) unless have_rendered_something

      end
    end
  end
end