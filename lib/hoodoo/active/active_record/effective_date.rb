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

        # TODO after specs: check if this is necessary
        # Define a model for the history entries which is namespaced with the
        # original model's name. So if the original model is called
        # Post, the history model will be PostHistoryEntry.
        history_klass = Class.new(ActiveRecord::Base) do
          self.primary_key = :id
          self.table_name = model.effective_history_table
        end
        Object.const_set model.history_model_name, history_klass


        # Define a scope for the model which finds records that are effective
        # at the provided date time.
        model.scope :effective_dated, ->( date_time ) do
          # TODO do join here
          utc_date_time = date_time.utc

          model.
            where("#{model.effective_start_column} is null or ? >= #{model.effective_start_column}", utc_date_time).
            where("#{model.effective_end_column} is null or ? < #{model.effective_end_column}", utc_date_time)
        end

      end

      module ClassMethods

        # Return the model with the specified ident, effective at the specified
        # date_time.
        #
        # +primary_key+:: The primary key column value of the desired record.
        #
        # +date_time+::   (Optional) Time at which the record is effective,
        #                 defaulting to the current time UTC.
        #
        def find_at( primary_key, date_time=Time.now.utc )
          formatted_model_attributes = self.attribute_names.join(", ")
          sql = %{
            SELECT #{formatted_model_attributes} FROM (
              SELECT #{formatted_model_attributes}, null AS effective_end FROM #{self.table_name} WHERE #{self.model_pkey} = ? AND created_at <= ?
              UNION ALL
              SELECT #{self.history_column_mapping}, effective_end FROM #{self.effective_history_table} WHERE uuid = ? AND effective_end > ?
            ) ORDER BY CASE WHEN effective_end IS NULL THEN 0 ELSE 1 END, effective_end DESC limit 1
          }

          self.find_by_sql([sql, primary_key, date_time, primary_key, date_time]).first
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

        # Get the symbolised name of the history table for model. This defaults
        # to the name of the model's table concatenated with _history_entries.
        # So if the table name is :posts, the history table would be
        # :posts_history_entries.
        #
        def effective_history_table
          if !class_variable_defined?( :@@effective_history_table )
            table_name = (self.table_name.to_s + "_history_entries").to_sym
            class_variable_set( :@@effective_history_table, table_name )
          end

          return class_variable_get( :@@effective_history_table )
        end

        # Get the symbolised name of the column which is used as start date of
        # this model. This defaults to :effective_start.
        #
        def effective_start_column
          if class_variable_defined?( :@@effective_start_column )
            return class_variable_get( :@@effective_start_column )
          else
            return :effective_start
          end
        end

        # Get the symbolised name of the column which is used as end date of this
        # model. This defaults to :effective_end.
        #
        def effective_end_column
          if class_variable_defined?( :@@effective_end_column )
            return class_variable_get( :@@effective_end_column )
          else
            return :effective_end
          end
        end

        ########################################################################
        # Setters for effective dating field names                             #
        ########################################################################

        # Set the name of the field which stores the start date for this model.
        #
        # +effective_start_column_name+:: String or Symbol name of the column.
        #
        def effective_date_history_table=( effective_start_history_table )
          class_variable_set( '@@effective_history_table', effective_start_history_table.to_sym )
        end

        # Set the name of the field which stores the start date for this model.
        #
        # +effective_start_column_name+:: String or Symbol name of the column.
        #
        def effective_date_start_column=( effective_start_column_name )
          class_variable_set( '@@effective_start_column', effective_start_column_name.to_sym )
        end

        # Set the name of the field which stores the end date for this model.
        #
        # +effective_end_column_name+:: String or Symbol name of the column.
        #
        def effective_date_end_column=( effective_end_column_name )
          class_variable_set( '@@effective_end_column', effective_end_column_name.to_sym )
        end

        def model_pkey
          self.primary_key || :id
        end

        def history_model_name
          self.to_s << "HistoryEntry"
        end

        def history_model
          history_model_name.constantize
        end

        def history_column_mapping
          desired_attributes = self.attribute_names.dup
          # TODO test the assumption that id is always first or get the index of
          # the primary key column and make it robust
          desired_attributes[0] = "uuid as " << desired_attributes[0]
          desired_attributes.join(", ")
        end

      end
    end
  end
end
