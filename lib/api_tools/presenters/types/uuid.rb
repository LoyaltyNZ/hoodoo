########################################################################
# File::    documented_uuid.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Presenters::BaseDSL field implementation
#           which supports a field defined to contain a UUID that
#           (optionally) can be verified as referring to a specific
#           other Resource.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
#           31-Oct-2014 (ADH): Moved to generic presenter layer from
#                              documented data layer.
########################################################################

module ApiTools
  module Presenters
    # A JSON UUID schema member
    class UUID < ApiTools::Presenters::Field

      # The optional associated resource kind, as a symbol (e.g. ':Product').
      attr_accessor :resource

      # Initialize a UUID instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :resource => :Product, :required => true
      def initialize(name, options = {})
        @resource = options.delete( :resource )
        super name, options
      end

      # Check if data is a valid UUID and return an ApiTools::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        unless ApiTools::UUID.valid?( data )
          errors.add_error(
            'generic.invalid_uuid',
            :message   => "Field `#{ full_path( path ) }` is an invalid UUID",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end
