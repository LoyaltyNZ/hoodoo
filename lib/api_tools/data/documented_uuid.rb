########################################################################
# File::    documented_uuid.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Data::DocumentedObject DSL field implementation
#           which supports a field defined to contain a UUID that
#           (optionally) can be verified as referring to a specific
#           other Resource. Instantiated via
#           ApiTools::Data::DocumentedObject#uuid.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools
  module Data
    # A JSON UUID schema member
    class DocumentedUUID < ApiTools::Presenters::Field

      # The optional associated resource kind, as a symbol (e.g. ':Product').
      attr_accessor :resource

      # Initialize a UUID instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :resource => :Product, :required => true
      def initialize(name, options = {})
        @resource = options.delete( :resource )
        super name, options
      end

      # Check if data is a valid UUID and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        if data.is_a? ::String
          if data.size != ApiTools::UUID::UUID_LENGTH
            errors << {:code=> 'generic.invalid_string', :message=>"UUID `#{full_path(path)}` is of incorrect length `#{data.size}` (should be `#{ApiTools::UUID::UUID_LENGTH}`)", :reference => full_path(path)}
          else
            # TODO: Maybe one day validate that the associated item is indeed
            #       of the kind in '@resource'.
          end
        else
          errors << {:code=> 'generic.invalid_string', :message=>"UUID `#{full_path(path)}` is invalid", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end
