########################################################################
# File::    documented_array.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Data::DocumentedObject DSL field implementation
#           allowing for documented Types references. Instantiated via
#           ApiTools::Data::DocumentedObject#array.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # As ApiTools::Presenters::Array but providing extended DSL facilities for
    # the Platform API documented Types and Resources collection.
    #
    class DocumentedArray < ApiTools::Data::DocumentedObject
      # Check if data is a valid Array and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        if data.is_a? ::Array
          data.each_with_index do |item, index|
            @properties.each do |name, property|
              rdata = (data.is_a?(::Hash) and data.has_key?(name)) ? data[name] : nil
              errors += property.validate(rdata, full_path(path))
            end
          end
        else
          errors << {:code=> 'generic.invalid_array', :message=>"Field `#{full_path(path)}` is an invalid array", :reference => full_path(path)}
        end
        errors

      end
    end
  end
end
