module ApiTools
  module Presenters
    # A JSON array schema member
    class Array < ApiTools::Presenters::Field

      include ApiTools::Presenters::BaseDSL

      # Check if data is a valid Array and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        if data.is_a? ::Array
          data.each_with_index do |item, index|
            @properties.each do |name, property|
              rdata = (item.is_a?(::Hash) and item.has_key?(name)) ? item[name] : nil
              indexed_path = "#{full_path(path)}[#{index}]"
              errors += property.validate(rdata, indexed_path )
            end
          end
        else
          errors << {:code=> 'generic.invalid_array', :message=>"Field `#{full_path(path)}` is an invalid array", :reference => full_path(path)}
        end

        errors
      end

      def render(data, target)
        data.each do |item|
          @properties.each do |name, property|
            property.render(item[name], target)
          end
        end
      end
    end
  end
end
