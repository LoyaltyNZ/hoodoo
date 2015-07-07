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

    # Effective dating support for an ActiveRecord model. Effective dating
    # allows the history of a model to be kept and subsequently looked up.
    # This module implements the class method .effective_at for finding
    # records effective at a given date time.
    module EffectiveDate

      # Set up effective dating when this module is included.
      def self.included( model )
        instantiate( model ) if model != Hoodoo::ActiveRecord::Base
      end

      # Set up effective dating for this model.
      def self.instantiate( model )
        model.extend( ClassMethods )

        # Define a model for the history entries which is namespaced with the
        # original model's name. So if the original model is called
        # Post, the history model will be PostHistoryEntry.
        history_klass = Class.new( ::ActiveRecord::Base ) do
          self.primary_key = :id
        end
        Object.const_set model.history_model_name, history_klass

      end

      module ClassMethods

        # Return an ActiveRecord::Relation containing the models which are
        # effective at the specified date_time.
        #
        # +primary_key+:: The primary key column value of the desired record.
        #
        # +date_time+:: (Optional) Time at which the records are effective,
        #               defaulting to the current time UTC.
        #
        def effective_at( date_time=Time.now )

          # Convert the date time to UTC
          date_time = date_time.utc

          # Create a string that specifies this model's attributes joined by
          # commas for use in a SQL query.
          formatted_model_attributes = self.attribute_names.join( ", " )

          # Escape user provided data
          safe_date_time = sanitize( date_time )

          # A query that combines historical and current records which are
          # effective at the specified date time.
          nested_query = %{
            (
              SELECT #{ formatted_model_attributes }, null AS effective_end
              FROM #{ self.table_name }
              WHERE created_at <= #{ safe_date_time }

              UNION ALL

              SELECT #{ self._history_column_mapping }, effective_end
              FROM #{ self.effective_history_table }
              WHERE effective_end > #{ safe_date_time } AND created_at <= #{ safe_date_time }
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list effective records.
          select( formatted_model_attributes ).from( nested_query )

        end

        # The String name of the model which represents history entries for this
        # model.
        def history_model_name
          self.to_s << "HistoryEntry"
        end

        # Forms and returns string which maps history table column names to the
        # primary table column names for use in SQL queries.
        #
        def _history_column_mapping

          desired_attributes = self.attribute_names.dup

          primary_key_index = desired_attributes.index( self.model_pkey )
          desired_attributes[ primary_key_index ] =
            "uuid as " << desired_attributes[ primary_key_index ]

          desired_attributes.join( ", " )

        end

        # Get the symbolised name of the history table for model. This defaults
        # to the name of the model's table concatenated with _history_entries.
        # So if the table name is :posts, the history table would be
        # :posts_history_entries.
        #
        def effective_history_table
          self.history_model_name.constantize.table_name
        end

        # The name of this model's primary key. This can be set via the
        # ActiveRecord setter self.primary_key=(). The default is "id".
        def model_pkey
          self.primary_key || "id"
        end

        # Set the name of the table which stores the history entries for this
        # model.
        #
        # +effective_start_history_table+:: String or Symbol name of the table.
        #
        def effective_date_history_table=( effective_start_history_table )
          history_model_name.constantize.table_name =
            effective_start_history_table
        end

      end
    end
  end
end
