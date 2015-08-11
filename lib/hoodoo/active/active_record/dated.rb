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
    # == Overview
    #
    # This mixin adds finder methods to the model it is applied to (see
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dated and
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dated_at). These finders require
    # two database tables in order to function correctly - the primary table
    # (the model table) and a history table. When a record is updated it should
    # be moved to the history table and a new record inserted with the new
    # values. When a record is deleted it should be moved to the history
    # table. This can be done manually with application code, or by things like
    # SQL triggers (see later).
    #
    # Dating is only enabled if the including class explicitly calls the
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dating_enabled method.
    #
    # == Database table requirements
    #
    # In all related tables, all date-time values must be stored as UTC.
    #
    # The primary table _must_ have a unique column named +id+ and two
    # timestamp columns named +updated_at+ and +created_at+ which both need
    # to be set by the application code (the ActiveRecord +timestamps+ macro
    # in a migration file defines appropriate columns).
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
    #    determines when the history entry was effective to (exclusive). A record
    #    is considered to be effective at a particular time if that time is the
    #    same or after the +effective_start+ and before the +effective_end+.
    #
    #    The +effective_start+ must be set to the +effective_end+ of the last
    #    record with same +uuid+, or to the +created_at+ of the record if there
    #    is no previous records with the same +uuid+.
    #
    #    The +effective_end+ must be set to the current time (UTC) when
    #    deleting a record or to the updated record's +updated_at+ when updating
    #    a record.
    #
    # Additionally there are two constraints on the history table that must not
    # be broken for the finder methods to function correctly:
    #
    # 1. When adding a record to the history table its +effective_end+ must be
    #    after all other records in the history table with the same +uuid+.
    #
    # 2. When inserting a new record to the primary table its +id+ must not
    #    exist in the history table.
    #
    # The history table name defaults to the name of the primary table
    # concatenated with +_history_entries+. This can be overriden when calling
    # Hoodoo::ActiveRecord::Dated::ClassMethods#dating_enabled.
    #
    # Example:
    #
    #     class Post < ActiveRecord::Base
    #       include Hoodoo::ActiveRecord::Dated
    #       dating_enabled( history_table_name: 'historical_posts' )
    #     end
    #
    # == Migration assistance
    #
    # Compatible database migration generators are included in +service_shell+.
    # These migrations create the history table and add database triggers
    # (PostgreSQL specific) which will handle the creation of the appropriate
    # history entry when a record is deleted or updated without breaking the
    # history table constraints. See
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
        model.class_attribute(
          :nz_co_loyalty_hoodoo_dated_with,
          {
            :instance_predicate => false,
            :instance_accessor  => false
          }
        )

        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
        super( model )
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

        # Activate historic dating for this model.
        #
        # See the module documentation for Hoodoo::ActiveRecord::Dated for
        # full information on dating, table requirements, default table names
        # and so forth.
        #
        # *Named* parameters are:
        #
        # +history_table_name+:: Optional String or Symbol name of the table
        #                        which stores the history entries for this
        #                        model. If omitted, defaults to the value
        #                        described by the documentation for
        #                        Hoodoo::ActiveRecord::Dated.
        #
        def dating_enabled( history_table_name: self.table_name + '_history_entries' )

          # Define an anonymous model for the history entries.

          history_klass = Class.new( ::ActiveRecord::Base ) do
            self.primary_key = :id
            self.table_name  = history_table_name
          end

          # Record the anonymous model class in a namespaced class attribute
          # for reference in the rest of the dating code via #dated_with().

          self.nz_co_loyalty_hoodoo_dated_with = history_klass

        end

        # Return an ActiveRecord::Relation containing the model instances which
        # are effective at +context.request.dated_at+. If this value is nil the
        # current time in UTC is used.
        #
        # If historic dating hasn't been enabled via a call to #dating_enabled,
        # then the default 'all' scope is returned instead.
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

        # Return an ActiveRecord::Relation scoping a query to include only model
        # instances that are relevant/effective at the specified date_time.
        #
        # If historic dating hasn't been enabled via a call to #dating_enabled,
        # then the default 'all' scope is returned instead.
        #
        # +date_time+:: (Optional) A Time or DateTime instance, or a String that
        #               can be converted to a DateTime instance, for which the
        #               "effective dated" scope is to be constructed.
        #
        def dated_at( date_time = Time.now )

          dating_table_name = dated_with_table_name()
          return all() if dating_table_name.nil? # "Model.all" -> returns anonymous scope

          # Rationalise and convert the date time to UTC.

          date_time = Hoodoo::Utilities.rationalise_datetime( date_time ).utc

          # Create a string that specifies this model's attributes escaped and
          # joined by commas for use in a SQL query.

          formatted_model_attributes = Hoodoo::ActiveRecord::Dated.sanitised_column_string( self )

          # Convert date_time to a String suitable for an SQL query.

          string_date_time = sanitize( date_time )

          # A query that combines historical and current records which are
          # effective at the specified date time.

          nested_query = %{
            (
              SELECT #{ formatted_model_attributes } FROM (
                SELECT #{ formatted_model_attributes }, updated_at as effective_start, null AS effective_end
                FROM #{ self.table_name }

                UNION ALL

                SELECT #{ self.dated_with_history_column_mapping }, effective_start, effective_end
                FROM #{ dating_table_name }
              ) AS u
              WHERE effective_start <= #{ string_date_time } AND (effective_end > #{ string_date_time } OR effective_end IS NULL)
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list a dated or current
          # record.

          return from( nested_query )
        end

        # Return an ActiveRecord::Relation scoping a query that would include
        # all historical and current model instances.
        #
        # If historic dating hasn't been enabled via a call to #dating_enabled,
        # then the default 'all' scope is returned instead.
        #
        def dated_historical_and_current

          dating_table_name = dated_with_table_name()
          return all() if dating_table_name.nil? # "Model.all" -> returns anonymous scope

          # Create a string that specifies this model's attributes escaped and
          # joined by commas for use in a SQL query.

          formatted_model_attributes = Hoodoo::ActiveRecord::Dated.sanitised_column_string( self )

          # A query that combines historical and current records.

          nested_query = %{
            (
              SELECT #{ formatted_model_attributes }
              FROM #{ self.table_name }

              UNION ALL

              SELECT #{ self.dated_with_history_column_mapping }
              FROM #{ dating_table_name }
            ) AS #{ self.table_name }
          }

          # Form a query which uses ActiveRecord to list current and dated
          # records.

          return from( nested_query )
        end

        # Returns the anonymous ActiveRecord::Base instance used for this
        # model's history entries, or +nil+ if historic dating has not been
        # enabled via a prior call to #dating_enabled.
        #
        def dated_with
          return self.nz_co_loyalty_hoodoo_dated_with
        end

        # Get the symbolised name of the history table for model. This defaults
        # to the name of the model's table concatenated with +_history_entries+.
        # If the table name is +:posts+, the history table would be
        # +:posts_history_entries+.
        #
        # If historic dating hasn't been enabled via a call to #dating_enabled,
        # returns +nil+.
        #
        def dated_with_table_name
          instance = self.dated_with()
          instance.nil? ? nil : instance.table_name
        end

        protected

        # Forms and returns string which maps history table column names to the
        # primary table column names for use in SQL queries.
        #
        def dated_with_history_column_mapping
          desired_attributes = self.attribute_names.dup

          # Locate the primary key field, which must be called "id".

          primary_key_index = desired_attributes.index( 'id' )

          # Sanitise the attribute names.

          desired_attributes.map!{ | c | ActiveRecord::Base.connection.quote_column_name( c ) }

          # Map the primary key.

          desired_attributes[ primary_key_index ] = 'uuid as ' << desired_attributes[ primary_key_index ]

          return desired_attributes.join( ',' )
        end

      end
    end
  end
end
