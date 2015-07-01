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

        # Redefine reload
        model.send(:define_method, :reload) do

          # Find the primary key value of the effective record with this group
          # id.
          primary_col = self.class.primary_key_column
          effective_primary_key = self.class.find_at(
            self.send( self.class.group_id_column )
          ).try( primary_col )

          if effective_primary_key.present?

            # An effective record was found with this model's group id. Make
            # this model point to it.

            self.send( "#{primary_col}=", effective_primary_key )

          else

            # There is no effective record with this group id, mark this model
            # as destroyed.

            @destroyed = true
            freeze

          end

          super() unless destroyed? # TODO

        end

        # Define a scope for the model which finds records that are effective
        # at the provided date time.
        model.scope :effective_dated, ->( date_time ) do
          utc_date_time = date_time.utc

          model.
            where("#{model.effective_start_field} is null or ? >= #{model.effective_start_field}", utc_date_time).
            where("#{model.effective_end_field} is null or ? < #{model.effective_end_field}", utc_date_time)
        end

        # A database trigger may intercept updates and:
        #  * End-date the existing record
        #  * Insert a new record with the new values.
        #
        # This after_save hook will ensure the model instance points to the
        # effective record with this model's group id, or mark this model as
        # destroyed if there is no such record.
        #
        model.after_save do
          reload
        end

      end

      module ClassMethods

        # Return the model with the specified ident, effective at the specified
        # date_time.
        #
        # +group_id+:: The group id column value of the desired record.
        #
        # +date_time+:: (Optional) Time at which the record is effective,
        #               defaulting to the current time UTC.
        #
        def find_at( group_id, date_time=Time.now.utc )
          where( "#{group_id_column}" => group_id ).effective_dated( date_time ).first
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

        # The name of the column which stores the group id. This can be set via
        # #group_id_column=, defaulting to :id.
        #
        def group_id_column
          if class_variable_defined?( :@@effective_group_id_column )
            return class_variable_get( :@@effective_group_id_column )
          else
            return :id
          end
        end

        # The name of the primary key column. This can be set via
        # #primary_key_column=, defaulting to :activerecord_id.
        #
        def primary_key_column
          if class_variable_defined?( :@@effective_primary_key_column )
            return class_variable_get( :@@effective_primary_key_column )
          else
            return :activerecord_id
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

        # Set the name of the column which stores the group id. This can be read
        # via #group_id_column, defaulting to :id.
        #
        # +group_id_column_name+:: The symbolised name of the column which holds
        #                          the group_id.
        #
        def group_id_column=( group_id_column_name )
          class_variable_set( :@@effective_group_id_column, group_id_column_name )
        end

        # Set the name of the column which stores the primary key. This can be
        # read via #primary_key_column, defaulting to :activerecord_id.
        #
        # +primary_key_column_name+:: The symbolised name of the primary key
        #                             column.
        #
        def primary_key_column=( primary_key_column_name )
          class_variable_set( :@@effective_primary_key_column, primary_key_column_name )
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
