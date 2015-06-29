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
        instantiate( model ) if model != Hoodoo::ActiveRecord::Base
      end

      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        # Set the configured primary key
        model.primary_key = model.primary_key_field

        # Force ActiveRecord to always insert instead of update
        model.send(:define_method, :new_record?, lambda { true })

        # Force ActiveRecord to insert every attribute on every write, otherwise
        # it will check new_record? which is overriden to always be true, then
        # it will do an insert but only with the attributes that are dirty.
        model.send(:define_method, :partial_writes?, lambda { false })

        # Define a scope for the model which finds records that are effective
        # at the provided date time.
        model.scope :effective_dated, ->( date_time ) do
          utc_date_time = date_time.utc

          model.
            where("#{model.effective_start_field} is null or ? >= #{model.effective_start_field}", utc_date_time).
            where("#{model.effective_end_field} is null or ? < #{model.effective_end_field}", utc_date_time)
        end

        model.before_save do

          # Set the effective_start field to now
          self.send( "#{self.class.effective_start_field}=", Time.now.utc )

          # Set the id field to a concatenation of the uuid field value and the
          # effective start field value with an underscore between them.
          self.send(
            "#{self.class.primary_key}=",
            self.send( self.class.uuid_field ) +
            "_" +
            Hoodoo::ActiveRecord::EffectiveDate.time_to_s_with_large_precision(
              self.send( self.class.effective_start_field )
            )
          )

        end
      end

      # Format time as a string with 10^-7 precision, multiplied to be a
      # whole number and converted to a string.
      #
      # +time_to_convert+:: Time object to convert
      #
      def self.time_to_s_with_large_precision(time_to_convert)
        (time_to_convert.to_f * 10000000).to_i.to_s
      end

      module ClassMethods

        #
        def find_at( ident, date_time=Time.now.utc )
          found = where( "#{uuid_field}" => ident ).effective_dated( date_time )
          if found.count == 0
            nil
          else
            found.first
          end
        end

        #
        def list_at( date_time=Time.now.utc )
          effective_dated( date_time )
        end

        ########################################################################
        # Getters for effective dating field names                             #
        ########################################################################

        # Get the symbolised name of the field which is used as the uuid for
        # this model. This defaults to :id.
        #
        def uuid_field
          if class_variable_defined?( :@@effective_uuid_field )
            return class_variable_get( :@@effective_uuid_field )
          else
            return :uuid
          end
        end

        # Get the symbolised name of the field which is used as the ActiveRecord
        # primary key of this model. This defaults to :activerecord_id.
        #
        def primary_key_field
          :activerecord_id
        end

        # Get the symbolised name of the field which is used as start date of
        # this model. This defaults to :effective_start.
        #
        def effective_start_field
          if class_variable_defined?( :@@effective_start_field )
            return class_variable_get( :@@effective_start_field )
          else
            return :effective_start
          end
        end

        # Get the symbolised name of the field which is used as end date of this
        # model. This defaults to :effective_end.
        #
        def effective_end_field
          if class_variable_defined?( :@@effective_end_field )
            return class_variable_get( :@@effective_end_field )
          else
            return :effective_end
          end
        end

        ########################################################################
        # Setters for effective dating field names                             #
        ########################################################################

        # Set the name of the UUID field for this model. This is not the primary
        # key field as the primary key is populated with data used to ensure
        # ActiveRecord maintains reference to the correct record in the
        # database across updates.
        #
        # +effective_uuid_field_name+:: String or Symbol name of the field.
        #
        def effective_date_uuid_field( effective_uuid_field_name )
          class_variable_set( '@@effective_uuid_field', effective_uuid_field_name.to_sym )
        end

        # Set the name of the field which ActiveRecord should use as the
        # primary key for this model. This field will be automatically
        # populated with a concatenation of the id_field and the
        # effective_start field.
        #
        # +effective_primary_key_field_name+:: String or Symbol name of the
        #                                      field.
        #
        def effective_date_primary_key_field( effective_primary_key_field_name )
          class_variable_set( '@@effective_primary_key_field', effective_primary_key_field_name.to_sym )
        end

        # Set the name of the field which stores the start date for this model.
        #
        # +effective_start_field_name+:: String or Symbol name of the field.
        #
        def effective_date_start_field( effective_start_field_name )
          class_variable_set( '@@effective_start_field', effective_start_field_name.to_sym )
        end

        # Set the name of the field which stores the end date for this model.
        #
        # +effective_end_field_name+:: String or Symbol name of the field.
        #
        def effective_date_end_field( effective_end_field_name )
          class_variable_set( '@@effective_end_field', effective_end_field_name.to_sym )
        end

      end
    end
  end
end
