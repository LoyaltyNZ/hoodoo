########################################################################
# File::    dated.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing as-per-API-standard dating support.
# ----------------------------------------------------------------------
#           14-Jul-2015 (ADH): Created.
#           21-Jul-2015 (RJS): Functionality implemented.
########################################################################

module Hoodoo
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # as-per-API-standard dating support. See
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dated for details.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Dated

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Dated
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Dated::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # Additionally a history model is created for interacting with the
      # history records.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        # Define a model for the history entries which is namespaced with the
        # original model's name. So if the original model is called
        # Post, the history model will be PostHistoryEntry.
        history_klass = Class.new( ::ActiveRecord::Base ) do
          self.primary_key = :id
          self.table_name  = model.table_name + "_history_entries"
        end
        Object.const_set( model.dated_history_model_name, history_klass )

      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Dated::included.
      #
      module ClassMethods

        # Return an ActiveRecord::Relation containing the model instances which
        # are effective at +context.request.dated_at+. If this value is nil the
        # current time in UTC is used.
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def dated( context )
          date_time = context.request.dated_at || Time.now
          return self.dated_at( date_time )
        end

        # Return an ActiveRecord::Relation containing the models instances which
        # are effective at the specified date_time.
        #
        # +date_time+:: A Time or DateTime instance, or a String that can be
        #               converted to a DateTime instance, for which the
        #               "effective dated" scope is to be constructed.
        #
        def dated_at( date_time = Time.now )

          # Rationalise and convert the date time to UTC
          date_time = Hoodoo::Utilities.rationalise_datetime( date_time ).utc

          # Create a string that specifies this model's attributes joined by
          # commas for use in a SQL query.
          formatted_model_attributes = self.attribute_names.join( "," )

          # Convert date_time to a String suitable for an SQL query
          string_date_time = sanitize( date_time )

          # A query that combines historical and current records which are
          # effective at the specified date time.
          nested_query = %{
            (
              SELECT #{ formatted_model_attributes } FROM (
                SELECT #{ formatted_model_attributes }, updated_at as effective_start, null AS effective_end
                FROM #{ self.table_name }

                UNION ALL

                SELECT #{ self.history_column_mapping }, effective_start, effective_end
                FROM #{ self.dated_history_table_name }
              ) AS u
              WHERE effective_start <= #{ string_date_time } AND (effective_end > #{ string_date_time } OR effective_end IS NULL)
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list effective records.
          from( nested_query )

        end

        # Return an ActiveRecord::Relation containing all historical and current
        # model instances.
        #
        def historical_and_current

          # Create a string that specifies this model's attributes joined by
          # commas for use in a SQL query.
          formatted_model_attributes = self.attribute_names.join( "," )

          # A query that combines historical and current records.
          nested_query = %{
            (
              SELECT #{ formatted_model_attributes }
              FROM #{ self.table_name }

              UNION ALL

              SELECT #{ self.history_column_mapping }
              FROM #{ self.dated_history_table_name }
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list effective records.
          from( nested_query )

        end

        # The String name of the model which represents history entries for this
        # model.
        def dated_history_model_name

          "NzCoLoyaltyHoodoo#{self.to_s}HistoryEntry"

        end

        # Get the symbolised name of the history table for model. This defaults
        # to the name of the model's table concatenated with +_history_entries+.
        # If the table name is :posts, the history table would be
        # :posts_history_entries.
        #
        def dated_history_table_name

          self.dated_history_model_name.constantize.table_name

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
        def dated_history_table_name=( effective_start_history_table )

          dated_history_model_name.constantize.table_name = effective_start_history_table

        end

        protected

        # Forms and returns string which maps history table column names to the
        # primary table column names for use in SQL queries.
        #
        def history_column_mapping

          desired_attributes = self.attribute_names.dup

          primary_key_index = desired_attributes.index( self.model_pkey )
          desired_attributes[ primary_key_index ] = "uuid as " << desired_attributes[ primary_key_index ]

          desired_attributes.join( ", " )

        end

      end
    end
  end
end
