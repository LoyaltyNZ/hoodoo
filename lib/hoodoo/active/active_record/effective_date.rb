########################################################################
# File::    effective_date.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing enhanced find mechanisms for +show+ and +list+
#           action handling.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    #
    module EffectiveDate

      #
      def self.included( model )
        if model != Hoodoo::ActiveRecord::Base
          instantiate( model )
        end
      end

      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        model.before_validation do
          self.send("#{self.class.effective_start_field}=", Time.now.utc) if self.send(self.class.effective_start_field).nil?
        end
      end

      #
      module ClassMethods

        #
        def effective_date_start_field( effective_start_field_name )
          class_variable_set( '@@effective_start_field', effective_start_field_name.to_sym )
        end

        #
        def effective_date_end_field( effective_end_field_name )
          class_variable_set( '@@effective_end_field', effective_end_field_name.to_sym )
        end

        #
        def find_at( ident, date_time=Time.now.utc )
          valid_date_time = date_time.utc
          checker = where( uuid: ident )
                    .where("#{effective_start_field} is null or ? >= #{effective_start_field}", valid_date_time)
                    .where("#{effective_end_field} is null or ? < #{effective_end_field}", valid_date_time)

          return checker.first unless checker.count == 0

          return nil
        end

        def effective_start_field
          if class_variable_defined?( :@@effective_start_field )
            return class_variable_get( :@@effective_start_field )
          else
            return :effective_start
          end
        end

        def effective_end_field
          if class_variable_defined?( :@@effective_end_field )
            return class_variable_get( :@@effective_end_field )
          else
            return :effective_end
          end
        end

      end
    end
  end
end
