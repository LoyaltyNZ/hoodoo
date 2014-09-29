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

        puts "!"*80
        puts "Render current target #{target.inspect}"
        puts "Data #{data.inspect}"
        puts "Path #{@path}"
        puts "Properties #{@properties.inspect}"

        # Work out where in the target data to build an array

        path = (@mapping.nil? ? @path : @mapping).clone
        root = target
        final = path.pop
        path.each do |element|
          root[element] = {} unless root.has_key?(element)
          root = root[element]
        end

        root[final] = []
        path << final

        data.each do |item|
          subtarget = {}
          @properties.each do |name, property|
            property.render(item[name], subtarget)
          end
          path.each do |element|
            puts "SUB #{element}"
            subtarget = subtarget[element]
          end
          root[final] << subtarget
        end
      end
    end
  end
end
