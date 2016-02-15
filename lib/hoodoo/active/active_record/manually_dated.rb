########################################################################
# File::    manually_dated.rb
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
    # as-per-API-standard dating support with services needing to know that
    # dating is enabled and cooperate with this mixin's API, rather than
    # working automatically via database triggers as per
    # Hoodoo::ActiveRecord::Dated. The latter is close to transparent for
    # ActiveRecord-based code, but it involves very complex database queries
    # that can have high cost and is tied into PostgreSQL.
    #
    # Depends upon and auto-includes Hoodoo::ActiveRecord::Finder.
    #
    # == Overview
    #
    # This mixin lets you record and retrieve the historical state of any
    # given ActiveRecord model. This is achieved by adding two date/time
    # columns to the model and using these to track the start (inclusive) and
    # end (exclusive and always set to precisely DATE_MAXIMUM for "this is the
    # 'contemporary' record) date/times for which a particular row is valid.
    #
    # The majority of the functionality is implemented within class methods
    # defined in module Hoodoo::ActiveRecord::ManuallyDated::ClassMethods.
    #
    # == Prerequisites
    #
    # A table in the database needs to have various changes and additions to
    # support manual dating. For these to be possible:
    #
    # * Your database table may not already have columns called +uuid+,
    #   +effective_start+ or +effective_end+. If it does, you'll need to first
    #   migrate this to change the names and update any references in code.
    #
    # * Your database table must have a column called +created_at+ with the
    #   creation timestamp of a record which will become the time from which
    #   it is "visible" in historically-dated read queries. There can be no
    #   +NULL+ values in this column.
    #
    # * Your database table must have a column called +updated_at+ with a
    #   non +NULL+ value. If this isn't already present, migrate your data
    #   to add it, setting the initial value to the same as +created_at+.
    #
    # For data safety it is very strongly recommended that you add in database
    # level non-null constraints on +created_at+ and +updated_at+ if you don't
    # have them already. The ActiveRecord +change_column_null+ method can be
    # used in migrations to do this in a database-engine-neutral fashion.
    #
    # == Vital caveats
    #
    # Since both the 'contemporary' and historic states of the model are all
    # recorded in one table, anyone using this mechanism must ensure that
    # (unless they specifically want to run a query across all of the
    # representations) the mixin's scoping methods are _always_ used to target
    # either current, or historic, or specifically-dated rows only.
    #
    # With this mechanism in place, the +id+ attribute of the model is _still_
    # _a_ _unique_ _primary_ _key_ AND THIS IS *NO* *LONGER* THE RESOURCE
    # UUID. The UUID moves to a _non-unique_ +uuid+ column. When rendering
    # resources, YOU *MUST* USE THE +uuid+ COLUMN for the resource ID. This
    # is a potentially serious gotcha and strong test coverage is advised! If
    # you send back the wrong field value, it'll look like a reasonable UUID
    # but will not match any records at all through API-based interfaces,
    # assuming Hoodoo::ActiveRecord::Finder is in use for read-based queries.
    # The UUID will appear to refer to a non-existant resource.
    #
    # * The +id+ column becomes a unique database primary key and of little
    #   to no interest whatsoever to a service or API callers.
    #
    # * The +uuid+ column becomes the non-unique resource UUID which is of
    #   great interest to a service and API callers.
    #
    # * The +uuid+ column is also the target for foreign keys with
    #   relationships between records, NOT +id+. The relationships can
    #   only be used when scoped by date.
    #
    # == Accuracy
    #
    # Time accuracy is intentionally limited, to aid database indices and help
    # avoid clock accuracy differences across operating systems or datbase
    # engines. Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES
    # describes the accuracy applicable.
    #
    # If a record is, say, both created and then deleted within the accuracy
    # window, then a dated query attempting to read the resource state from
    # that (within-accuracy) identical time will return an undefined result.
    # It might find the resource before it were deleted, or might not find the
    # resource because it considers it to be no longer current. Of course, any
    # dated query from outside the accuracy window will work as you would
    # expect; only rapid changes in state within the accuracy window result in
    # ambiguity.
    #
    # == Typical workflow
    #
    # Having included the mixin, run any required migrations (see below) and
    # declared manual dating as active inside your <tt>ActiveRecord::Base</tt>
    # subclass by calling
    # Hoodoo::ActiveRecord::ManuallyDated::ClassMethods#manual_dating_enabled,
    # you *MUST* include the ActiveRecord::Relation instances (scopes) inside
    # any query chain used to read or write data.
    #
    # You might use Hoodoo::ActiveRecord::Finder#list_in or
    # Hoodoo::ActiveRecord::Finder#acquire_in for +list+ or +show+ actions;
    # such code changes from e.g.:
    #
    #     SomeModel.list_in( context )
    #
    # ...to:
    #
    #     SomeModel.manually_dated( context ).list_in( context )
    #
    # You MUST NOT update or delete records using conventional ActiveRecord
    # methods if you want to use manual dating to record state changes.
    # Instead, use
    # Hoodoo::ActiveRecord::ManuallyDated::ClassMethods#manually_dated_update_in
    # or
    # Hoodoo::ActiveRecord::ManuallyDated::ClassMethods#manually_dated_destruction_in.
    # For example to update a model based on the +context.request.body+ data
    # without changes to the item in +context.request.ident+, handling "not
    # found" or valiation error cases with the assumption that the
    # Hoodoo::ActiveRecord::ErrorMapping mixin is in use, do this:
    #
    #     result = SomeModel.manually_dated_destruction_in( context )
    #
    #     if result.nil?
    #       context.response.not_found( context.request.ident )
    #     elsif result.adds_errors_to?( context.response.errors ) == false
    #       rendered_data = render_model( result )
    #       context.response.set_data( rendered_data )
    #     end
    #
    # See the documentation for the update/destroy methods mentioned above for
    # information on overriding the identifier used to find the target record
    # and the attribute data used for updates.
    #
    # When rendering, you *MUST* remember to set the resource's +id+ field
    # from the model's +uuid+ field:
    #
    #     SomePresenter.render_in(
    #       context,
    #       model.attributes,
    #       {
    #         :uuid         => model.uuid, # <-- ".uuid" - IMPORTANT!
    #         :created_at   => model.created_at
    #       }
    #     )
    #
    # Likewise, remember to set foreign keys for any relational declarations
    # via the +uuid+ column - e.g. go from this:
    #
    #     member.account_id = account.id
    #
    # ...to this:
    #
    #     member.account_id = account.uuid
    #
    # ...with the relational declarations in Member changing from:
    #
    #     belongs_to :account
    #
    # ...to:
    #
    #     belongs_to :account, :primary_key => :uuid
    #
    # == Required migrations
    #
    # You must write an ActiveRecord migration for any table that wishes to
    # use manual dating. The template below can handle multiple tables in one
    # pass and can be rolled back safely *IF* no historic records have been
    # added. Rollback becomes impossible once historic entries appear.
    #
    #     require 'hoodoo/active'
    #
    #     class ConvertToManualDating < ActiveRecord::Migration
    #
    #       # This example migration can handle multiple tables at once - e.g. pass an
    #       # array of ":accounts, :members" if you were adding manual dating support to
    #       # tables supporting an Account and Member ActiveRecord model.
    #       #
    #       TABLES_TO_CONVERT = [ :table_name, :another_table_name, ... ]
    #
    #       # This will come in handy later.
    #       #
    #       SQL_DATE_MAXIMUM = ActiveRecord::Base.connection.quoted_date( Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM )
    #
    #       def up
    #
    #         # If you have any uniqueness constraints on this table, you'll need to
    #         # remove them and re-add them with date-based scope. The main table will
    #         # contain duplicated entries once historical versions of a row appear.
    #         #
    #         #   remove_index :table_name, <index fields(s) or name: 'index name'>
    #         #
    #         # For example, suppose you had declared this index somewhere:
    #         #
    #         #   add_index :accounts, :account_number, :unique => true
    #         #
    #         # Remove it with:
    #         #
    #         #   remove_index :accounts, :account_number
    #
    #         TABLES_TO_CONVERT.each do | table |
    #
    #           add_column table, :effective_start, :datetime, :null  => true # (initially, but see below)
    #           add_column table, :effective_end,   :datetime, :null  => true # (initially, but see below)
    #           add_column table, :uuid,            :string,   :limit => 32
    #
    #           add_index table, [        :effective_start, :effective_end ], :name => "index_#{ table }_start_end"
    #           add_index table, [ :uuid, :effective_start, :effective_end ], :name => "index_#{ table }_uuid_start_end"
    #
    #           # We can't allow duplicate UUIDs. Here's how to correctly scope based on
    #           # any 'contemporary' record, given its known fixed 'effective_end'.
    #           #
    #           ActiveRecord::Migration.add_index table,
    #                                             :uuid,
    #                                             :unique => true,
    #                                             :name   => "index_#{ table }_uuid_end_unique",
    #                                             :where  => "(effective_end = '#{ SQL_DATE_MAXIMUM }')"
    #
    #           # If there's any data in the table already, it can't have any historic
    #           # entries. So, we want to set the UUID to the 'id' field's old value,
    #           # but we can also leave the 'id' field as-is. New rows for historical
    #           # entries will acquire a new value of 'id' via Hoodoo.
    #           #
    #           execute "UPDATE #{ table } SET uuid = id"
    #
    #           # This won't follow the date/time rounding described by manual dating
    #           # but it's good enough for an initial migration.
    #           #
    #           execute "UPDATE #{ table } SET effective_start = created_at"
    #
    #           # Mark these records as contemporary/current.
    #           #
    #           execute "UPDATE #{ table } SET effective_end = '#{ ActiveRecord::Base.connection.quoted_date( Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM ) }'"
    #
    #           # We couldn't add the UUID column with a not-null constraint until the
    #           # above SQL had run to update any existing records with a value. Now we
    #           # should put this back in, for rigour. Likewise for the start/end times.
    #           #
    #           change_column_null table, :uuid,            false
    #           change_column_null table, :effective_start, false
    #           change_column_null table, :effective_end,   false
    #
    #         end
    #
    #         # Now add back any indices dropped earlier, but add them back as a
    #         # conditional index as shown earlier for the "uuid" column. For example,
    #         # suppose you had declared this index somewhere:
    #         #
    #         #   add_index :accounts, :account_number, :unique => true
    #         #
    #         # You need to have done "remove_index :accounts, :account_number" earlier;
    #         # then now add the new equivalent. You may well find you have to give it a
    #         # custom name to avoid hitting index name length limits in your database:
    #         #
    #         # ActiveRecord::Migration.add_index :accounts,
    #         #                                   :account_number,
    #         #                                   :unique => true,
    #         #                                   :name   => "index_#{ table }_account_number_end_unique",
    #         #                                   :where  => "(effective_end = '#{ SQL_DATE_MAXIMUM }')"
    #         #
    #         # You might want to perform more detailed analysis on your index
    #         # requirements once manual dating is enabled, but the above is a good rule
    #         # of thumb.
    #
    #       end
    #
    #       # This would fail if any historic entries now existed in the database,
    #       # because primary key 'id' values would get set to non-unique 'uuid'
    #       # values. This is intentional and required to avoid corruption; you
    #       # cannot roll back once history entries accumulate.
    #       #
    #       def down
    #
    #         # Remove any indices added manually at the end of "up", for example:
    #         #
    #         #   remove_index :accounts, :name => 'index_accounts_an_es_ee'
    #         #   remove_index :accounts, :name => 'index_accounts_an_ee'
    #
    #         TABLES_TO_CONVERT.each do | table |
    #
    #           remove_index table, :name => "index_#{ table }_id_end"
    #           remove_index table, :name => "index_#{ table }_id_start_end"
    #           remove_index table, :name => "index_#{ table }_start_end"
    #
    #           execute "UPDATE #{ table } SET id = uuid"
    #
    #           remove_column table, :uuid
    #           remove_column table, :effective_end
    #           remove_column table, :effective_start
    #
    #         end
    #
    #         # Add back any indexes you removed at the very start of "up", e.g.:
    #         #
    #         #   add_index :accounts, :account_number, :unique => true
    #
    #       end
    #     end
    #
    module ManuallyDated

      # In order for indices to work properly on +effective_end+ dates, +NULL+
      # values cannot be permitted as SQL +NULL+ is magic and means "has no
      # value", so such a value in a column prohibits indexing.
      #
      # We might have used a +NULL+ value in the 'end' date to mean "this is
      # the contemporary/current record", but since we can't do that, we need
      # the rather nasty alternative of an agreed constant that defines a
      # "large date" which represents "maximum possible end-of-time".
      #
      # SQL does not define a maximum date, but most implementations do.
      # PostgreSQL has a very high maximum year, while SQLite, MS SQL Server
      # and MySQL (following a cursory Google search for documentation) say
      # that the end of year 9999 is as high as it goes.
      #
      # To use this +DATE_MAXIMUM+ constant in raw SQL, be sure to format the
      # Time instance through your ActiveRecord database adapter thus:
      #
      #     ActiveRecord::Base.connection.quoted_date( Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM )
      #     # => returns "9999-12-31 23:59:59.000000" for PostgreSQL 9.4.
      #
      DATE_MAXIMUM = Time.parse( '9999-12-31T23:59:59.0Z' )

      # Rounding resolution, in terms of number of decimal places to which
      # seconds are rounded. Excessive accuracy makes for difficult, large
      # indices in the database and may fall foul of system / database
      # clock accuracy mismatches.
      #
      SECONDS_DECIMAL_PLACES = 2 # An Integer from 0 upwards

      # Instantiates this module when it is included.
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::ManuallyDated
      #       # ...
      #     end
      #
      # Depends upon and auto-includes Hoodoo::ActiveRecord::UUID and
      # Hoodoo::ActiveRecord::Finder.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        model.class_attribute(
          :nz_co_loyalty_hoodoo_manually_dated,
          {
            :instance_predicate => false,
            :instance_accessor  => false
          }
        )

        unless model == Hoodoo::ActiveRecord::Base
          model.send( :include, Hoodoo::ActiveRecord::UUID )
          model.send( :include, Hoodoo::ActiveRecord::Finder )
          instantiate( model )
        end

        super( model )
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::ManullyDated::ClassMethods methods are defined
      # as class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::ManuallyDated::included.
      #
      module ClassMethods

        # Activate manually-driven historic dating for this model.
        #
        # See the module documentation for Hoodoo::ActiveRecord::ManuallyDated
        # for full information on dating, column/attribute requirements and so
        # forth.
        #
        # When dating is enabled, a +before_save+ filter will ensure that the
        # record's +created_at+ and +updated_at+ fields are manually set to
        # the current time ("now"), if not already set by the time the filter
        # is run. The record's +effective_start+ time is set to match
        # +created_at+ if not already set and +effective_end+ is set to
        # Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM _if_ not already
        # set. The record's +uuid+ resource UUID is set to the value of the
        # +id+ column if not already set, which is useful for new records but
        # should never happen for history-savvy updates performed by this
        # mixin's code.
        #
        def manual_dating_enabled
          self.nz_co_loyalty_hoodoo_manually_dated = true

          # This is the 'tightest'/innermost callback available for creation.
          # Intentionally have nothing for updates/deletes as the high level
          # API here must be used; we don't want to introduce any more magic.

          before_create do
            now = Time.now.utc.round( SECONDS_DECIMAL_PLACES )

            self.created_at      ||= now
            self.updated_at      ||= now
            self.effective_start ||= self.created_at
            self.effective_end   ||= DATE_MAXIMUM
          end

          # This is very similar to the UUID mixin, but works on the 'uuid'
          # column. With manual dating, ActiveRecord's quirks with changing
          # the primary key column, but still doing weird things with an
          # attribute and accessor called "id", forces us to give up on any
          # notion of changing the primary key. Keep "id" unique. This means
          # the UUID mixin, if in use, is now setting the *real* per row
          # unique key, while the "uuid" contains the UUID that should be
          # rendered for the resource representation and will appear in more
          # than one database row if the record has history entries. Thus,
          # the validation is scoped to be unique only per "effective_end"
          # value.
          #
          # Since the X-Resource-UUID header may be used and result in an
          # attribute "id" being specified inbound for new records, we take
          # any value of "id" if present and use that in preference to a
          # totally new UUID in order to deal with that use case.

          validate( :on => :create ) do
            self.uuid ||= self.id || Hoodoo::UUID.generate()
          end

          validates(
            :uuid,
            {
              :uuid       => true,
              :presence   => true,
              :uniqueness => { :scope => :effective_end },
            }
          )

          # Lastly, we must specify an acquisition scope that's based on
          # the "uuid" column only and *not* the "id" column.

          acquire_with_id_substitute( :uuid )

        end

        # If a prior call has been made to #manual_dating_enabled then this
        # method returns +true+, else +false+.
        #
        def manual_dating_enabled?
          return self.nz_co_loyalty_hoodoo_manually_dated == true
        end

        # Return an ActiveRecord::Relation instance which only matches records
        # that are relevant/effective at the date/time in the value of
        # +context.request.dated_at+ within the given +context+. If this value
        # is +nil+ then the current time in UTC is used.
        #
        # Manual historic dating must have been previously activated through a
        # call to #dating_enabled, else results will be undefined.
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def manually_dated( context )
          date_time = context.request.dated_at || Time.now
          return self.manually_dated_at( date_time )
        end

        # Return an ActiveRecord::Relation instance which only matches records
        # that are relevant/effective at the given date/time. If this value is
        # +nil+ then the current time in UTC is used.
        #
        # Manual historic dating must have been previously activated through a
        # call to #dating_enabled, else results will be undefined.
        #
        # +date_time+:: (Optional) A Time or DateTime instance, or a String that
        #               can be converted to a DateTime instance, for which the
        #               "effective dated" scope is to be constructed.
        #
        def manually_dated_at( date_time = Time.now )
          date_time  = date_time.to_time.utc.round( SECONDS_DECIMAL_PLACES )

          arel_table = self.arel_table()
          arel_query = arel_table[ :effective_start ].lteq( date_time ).
                       and(
                         arel_table[ :effective_end ].gt( date_time )
                         # .or(
                         #   arel_table[ :effective_end ].eq( nil )
                         # )
                       )

          where( arel_query )
        end

        # Return an ActiveRecord::Relation instance which only matches records
        # that are from the past. The 'current' record for any given UUID will
        # never be included by the scope.
        #
        # Manual historic dating must have been previously activated through a
        # call to #dating_enabled, else results will be undefined.
        #
        def manually_dated_historic
          where.not( :effective_end => DATE_MAXIMUM )
        end

        # Return an ActiveRecord::Relation instance which only matches records
        # that are 'current'. The historic/past records for any given UUID
        # will never be included in the scope.
        #
        # Manual historic dating must have been previously activated through a
        # call to #dating_enabled, else results will be undefined.
        #
        def manually_dated_contemporary
          where( :effective_end => DATE_MAXIMUM )
        end

        # Update a record with manual historic dating. This means that the
        # 'current' / most recent record is turned into a historic entry via
        # setting its +effective_end+ date, a duplicate is made and any new
        # attribute values are set in this duplicate. This new record is then
        # saved as the 'current' version. A transaction containing a database
        # lock over all history rows for the record via its UUID (+id+ column)
        # is used to provide concurrent access safety.
        #
        # The return value is complex:
        #
        # * If +nil+, the record that was to be updated could not be found.
        # * If not +nil+, an ActiveRecord model instance is returned. This is
        #   the new 'current' record, but it might not be saved; validation
        #   errors may have happened. You need to check for this before
        #   proceeding. This will _not_ be the same model instance found for
        #   the original, most recent / current record.
        #
        # If attempts to update the previous, now-historic record's effective
        # end date fail, an exception may be thrown as the failure condition
        # is unexpected (it will almost certainly be because of a database
        # connection failure). You _might_ need to call this method from a
        # block with a +rescue+ clause if you wish to handle those elegantly,
        # but it is probably a serious failure and the generally recommended
        # behaviour is to just let Hoodoo's default exception handler catch
        # the exception and return an HTTP 500 response to the API caller.
        #
        # _Unnamed_ parameters are:
        #
        # +context+::    Hoodoo::Services::Context instance describing a call
        #                context. This is typically a value passed to one of
        #                the Hoodoo::Services::Implementation instance methods
        #                that a resource subclass implements. This is used to
        #                find the record's UUID and new attribute information
        #                unless overridden (see named parameter list).
        #
        # Additional _named_ parameters are:
        #
        # +ident+::      UUID (32-digit +id+ column value) of the record to be
        #                updated. If omitted, +context.request.ident+ is used.
        #
        # +attributes+:: Hash of attributes to write (via ActiveRecord's
        #                +assign_attributes+ method) in order to perform the
        #                update. If omitted, +context.request.body+ is used.
        #
        # +scope+::      ActiveRecord::Relation instance providing the scope
        #                to use for database locks and acquiring the record
        #                to update. Defaults to #acquisition_scope for the
        #                prevailing +ident+ value.
        #
        def manually_dated_update_in( context,
                                      ident:      context.request.ident,
                                      attributes: context.request.body,
                                      scope:      all() )

          new_record        = nil
          retried_operation = false

          begin

            # 'requires_new' => exceptions in nested transactions will cause
            # rollback; see the comment documentation for the Writer module's
            # "persist_in" method for details.
            #
            self.transaction( :requires_new => true ) do

              lock_scope = scope.acquisition_scope( ident ).lock( true )
              self.connection.execute( lock_scope.to_sql )

              original = scope.manually_dated_contemporary().acquire( ident )
              break if original.nil?

              # The only way this can fail is by throwing an exception.
              #
              original.update_column( :effective_end, Time.now.utc.round( SECONDS_DECIMAL_PLACES ) )

              # When you 'dup' a live model, ActiveRecord clears the 'created_at'
              # and 'updated_at' values, and the 'id' column - even if you set
              # the "primary_key=..." value on the model to something else. Put
              # it all back together again.
              #
              # Duplicate, apply attributes, then overwrite anything that is
              # vital for dating so that the inbound attributes hash can't cause
              # any inconsistencies.
              #
              new_record = original.dup
              new_record.assign_attributes( attributes )

              new_record.id              = nil
              new_record.uuid            = original.uuid
              new_record.created_at      = original.created_at
              new_record.updated_at      = original.effective_end # (sic.)
              new_record.effective_start = original.effective_end # (sic.)
              new_record.effective_end   = DATE_MAXIMUM

              # Save with validation but no exceptions. The caller examines the
              # returned object to see if there were any validation errors.
              #
              new_record.save()

              # Must roll back if the new record didn't save, to undo the
              # 'effective_end' column update on 'original' earlier.
              #
              raise ::ActiveRecord::Rollback if new_record.errors.present?
            end

          rescue ::ActiveRecord::StatementInvalid => exception

            # By observation, PostgreSQL can start worrying about deadlocks
            # with the above. Leading theory is that it's "half way through"
            # inserting the new row when someone else comes along and waits
            # on the lock, but that new waiting thread has also ended up
            # capturing a lock on the half-inserted row (since inserting
            # involves lots of internal steps and locks).
            #
            # In such a case, retry. But only do so once; then give up.
            #
            if retried_operation == false && exception.message.downcase.include?( 'deadlock' )
              retried_operation = true

              # Give other Threads time to run, maximising chance of deadlock
              # being resolved before retry.
              #
              sleep( 0.1 )
              retry

            else
              raise exception

            end

          end # "begin"..."rescue"..."end"

          return new_record
        end

        # Analogous to #manually_dated_update_in and with the same return
        # value and exception generation semantics, so see that method for
        # those details.
        #
        # This particular method soft-deletes a record. It moves the 'current'
        # entry to being an 'historic' entry as in #manually_dated_update_in,
        # but does not then generate any new 'current' record. Returns +nil+
        # if the record couldn't be found to start with, else returns the
        # found and soft-deleted / now-historic model instance.
        #
        # Since no actual "hard" record deletion takes place, traditional
        # ActiveRecord concerns of +delete+ versus +destroy+ or of dependency
        # chain destruction do not apply. No callbacks or validations are run
        # when the record is updated (via ActiveRecord's #update_column). A
        # failure to update the record will result in an unhandled exception.
        # No change is made to the +updated_at+ column value.
        #
        # _Unnamed_ parameters are:
        #
        # +context+::    Hoodoo::Services::Context instance describing a call
        #                context. This is typically a value passed to one of
        #                the Hoodoo::Services::Implementation instance methods
        #                that a resource subclass implements. This is used to
        #                obtain the record's UUID unless overridden (see named
        #                parameter list).
        #
        # Additional _named_ parameters are:
        #
        # +ident+::      UUID (32-digit +id+ column value) of the record to be
        #                updated. If omitted, +context.request.ident+ is used.
        #
        # +scope+::      ActiveRecord::Relation instance providing the scope
        #                to use for database locks and acquiring the record
        #                to update. Defaults to #acquisition_scope for the
        #                prevailing +ident+ value.
        #
        def manually_dated_destruction_in( context,
                                           ident: context.request.ident,
                                           scope: all() )

          # See #manually_dated_update_in implementation for rationale.
          #
          return self.transaction do

            record = scope.manually_dated_contemporary().lock( true ).acquire( ident )
            record.update_column( :effective_end, Time.now.utc ) unless record.nil?
            record

          end
        end

      end
    end
  end
end
