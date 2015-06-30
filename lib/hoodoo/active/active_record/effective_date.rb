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

          # Wipe the primary key field (which id always refers to) so it can be
          # auto incremented by the database.
          self.id = nil

        end
      end

      module ClassMethods

        # Return the model with the specified ident, effective at the specified
        # date_time.
        #
        # +ident+:: The uuid column value of the desired record.
        #
        # +date_time+:: (Optional) Time at which the record is effective,
        #               defaulting to the current time UTC.
        #
        def find_at( ident, date_time=Time.now.utc )
          where( "#{uuid_column}" => ident ).effective_dated( date_time ).first
        end

        # Return the models which are effective at the specified date_time.
        #
        # +date_time+:: (Optional) Time at which the records are effective,
        #               defaulting to the current time UTC.
        #
        def list_at( date_time=Time.now.utc )
          effective_dated( date_time )
        end

        ########################################################################
        # Getters for effective dating field names                             #
        ########################################################################

        # The name of the column which stores the UUID. This can be set via
        # #uuid_column=, defaulting to :id.
        #
        def uuid_column
          if class_variable_defined?( :@@effective_uuid_column )
            return class_variable_get( :@@effective_uuid_column )
          else
            return :id
          end
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

        # Set the name of the column which stores the uuid. This can be read via
        # #uuid_column, defaulting to :id.
        #
        # +uuid_column_name+:: The symbolised name of the column which holds the
        #                      UUID.
        #
        def uuid_column=( uuid_column_name )
          class_variable_set( :@@effective_uuid_column, uuid_column_name )
        end

        # Set the name of the field which stores the start date for this model.
        #
        # +effective_start_field_name+:: String or Symbol name of the field.
        #
        def effective_date_start_field=( effective_start_field_name )
          class_variable_set( '@@effective_start_field', effective_start_field_name.to_sym )
        end

        # Set the name of the field which stores the end date for this model.
        #
        # +effective_end_field_name+:: String or Symbol name of the field.
        #
        def effective_date_end_field=( effective_end_field_name )
          class_variable_set( '@@effective_end_field', effective_end_field_name.to_sym )
        end

      end
    end
  end
end
