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
    # as-per-API-standard dating support.
    #
    # This mixin adds finder methods to the model it is applied to (see
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dated and
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dated_at). These finders require
    # two database tables in order to function correctly, the primary table
    # (the model table) and a history table. When a record is updated it should
    # be moved to the history table and a new record inserted with the new
    # values. When a record is deleted the it should be moved to the history
    # table.
    #
    # The primary table must have a unique column named +id+ and a
    # timestamp column named +updated_at+ which both need to be set by
    # application code.
    #
    # The history table requires the same columns as the primary table with two
    # differences:
    #
    # 1. The history table's +id+ column must be populated with any unique
    #    value whilst the history table's +uuid+ column must be populated with
    #    the primary table's +id+ value.
    #
    # 2. The history table must have two additional columns, +effective_start+
    #    and +effective_end+. The +effective_start+ column determines when the
    #    history entry becomes effective (inclusive) whilst the +effective_end+
    #    determines when the history entry is effective to (exclusive). A record
    #    is considered to be effective at a particular time if that time is the
    #    same or after the +effective_start+ and before the +effective_end+.
    #
    # Compatible database migration generators are included in Service_Shell
    # which will create the history table and add database triggers (PostgreSQL
    # specific) to create the appropriate history entry when a record is deleted
    # or updated. See
    # https://github.com/LoyaltyNZ/service_shell/blob/master/bin/generators/effective_date.rb
    # for more information.
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
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        # Define a model for the history entries which is namespaced with a
        # fixed prefix, NzCoLoyaltyHoodoo, to avoid namespace collisions and the
        # original model's name followed by the suffix HistoryEntry. If the
        # original model is called Post, the history model will be
        # NzCoLoyaltyHoodooPostHistoryEntry.
        #
        history_klass = Class.new( ::ActiveRecord::Base ) do
          self.primary_key = :id
          self.table_name  = model.table_name + "_history_entries"
        end
        Object.const_set( model.NZ_CO_LOYALTY_HOODOO_DATED_HISTORY_MODEL_NAME, history_klass )

      end

      # Forms a String containing the specified +model_klass+'s attribute names
      # escaped and joined with commas.
      #
      # +model_klass+ Class which responds to .attribute_names
      #
      def self.sanitised_column_string( model_klass )
        model_klass.attribute_names.map{ | c | ActiveRecord::Base.connection.quote_column_name( c ) }.join( ',' )
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
        # +date_time+:: (Optional) A Time or DateTime instance, or a String that
        #               can be converted to a DateTime instance, for which the
        #               "effective dated" scope is to be constructed.
        #
        def dated_at( date_time = Time.now )

          # Rationalise and convert the date time to UTC
          date_time = Hoodoo::Utilities.rationalise_datetime( date_time ).utc

          # Create a string that specifies this model's attributes escaped and
          # joined by commas for use in a SQL query.
          formatted_model_attributes = Hoodoo::ActiveRecord::Dated.sanitised_column_string( self )

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
                FROM #{ self.dated_with_table_name }
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
        def dated_historical_and_current

          # Create a string that specifies this model's attributes escaped and
          # joined by commas for use in a SQL query.
          formatted_model_attributes = Hoodoo::ActiveRecord::Dated.sanitised_column_string( self )

          # A query that combines historical and current records.
          nested_query = %{
            (
              SELECT #{ formatted_model_attributes }
              FROM #{ self.table_name }

              UNION ALL

              SELECT #{ self.history_column_mapping }
              FROM #{ self.dated_with_table_name }
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list effective records.
          from( nested_query )

        end

        # The String name of the model which represents history entries for this
        # model.
        #
        def NZ_CO_LOYALTY_HOODOO_DATED_HISTORY_MODEL_NAME

          "NzCoLoyaltyHoodoo#{self.to_s}HistoryEntry"

        end

        # Get the symbolised name of the history table for model. This defaults
        # to the name of the model's table concatenated with +_history_entries+.
        # If the table name is :posts, the history table would be
        # :posts_history_entries.
        #
        def dated_with_table_name

          self.NZ_CO_LOYALTY_HOODOO_DATED_HISTORY_MODEL_NAME.constantize.table_name

        end

        # Set the name of the table which stores the history entries for this
        # model.
        #
        # +dated_with_history_table+:: String or Symbol name of the table.
        #
        def dated_with_table_name=( dated_with_history_table )

          self.NZ_CO_LOYALTY_HOODOO_DATED_HISTORY_MODEL_NAME.constantize.table_name = dated_with_history_table

        end

        protected

        # Forms and returns string which maps history table column names to the
        # primary table column names for use in SQL queries.
        #
        def history_column_mapping

          desired_attributes = self.attribute_names.dup

          # Locate the primary key field
          primary_key_index = desired_attributes.index( self.primary_key || "id" )

          # Sanitise the attribute names
          desired_attributes.map!{ | c | ActiveRecord::Base.connection.quote_column_name( c ) }

          # Map the primary key
          desired_attributes[ primary_key_index ] = "uuid as " << desired_attributes[ primary_key_index ]

          desired_attributes.join( ',' )

        end

      end
    end
  end
end
