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
    module ManuallyDated

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
        # record's +created_at+ and +updated_at+ fields are manually set to the
        # current time ("now"), _if_ not already set by the time the filter is
        # run. The record's +effective_start+ time is set to match +created_at+
        # _if_ not already set. The record's +uuid+ resource UUID is set to the
        # value of the +id+ column if not already set, which is useful for new
        # records but should never happen for history-savvy updates performed
        # by this mixin's code.
        #
        def manual_dating_enabled
          self.nz_co_loyalty_hoodoo_manually_dated = true

          before_save do
            now = Time.now.utc

            self.created_at      ||= now
            self.updated_at      ||= now
            self.effective_start ||= self.created_at
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
          date_time = context.request.dated_at || Time.now.utc
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
        def manually_dated_at( date_time = Time.now.utc )
          date_time  = Hoodoo::Utilities.nanosecond_iso8601( date_time.utc )
          arel_table = self.arel_table()
          arel_query = arel_table[ :effective_start ].lteq( date_time ).
                       and(
                         arel_table[ :effective_end ].gt( date_time ).
                         or(
                           arel_table[ :effective_end ].eq( nil )
                         )
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
          where.not( :effective_end => nil )
        end

        # Return an ActiveRecord::Relation instance which only matches records
        # that are 'current'. The historic/past records for any given UUID
        # will never be included in the scope.
        #
        # Manual historic dating must have been previously activated through a
        # call to #dating_enabled, else results will be undefined.
        #
        def manually_dated_contemporary
          where( :effective_end => nil )
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

          new_record      = nil
          retry_operation = false

          begin
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
                original.update_column( :effective_end, Time.now.utc )

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
                new_record.effective_end   = nil

                # Save with validation but no exceptions. The caller examines the
                # returned object to see if there were any validation errors.
                #
                new_record.save()

                # Must roll back if the new record didn't save, to undo the
                # 'effective_end' column update on 'original' earlier.
                #
                raise ::ActiveRecord::Rollback if new_record.errors.present?
              end

              retry_operation = false

            rescue ::ActiveRecord::StatementInvalid => exception

              # By observation, PostgreSQL can start worrying about deadlocks
              # with the above. TODO: I don't know why; I can't see how it can
              # possibly end up trying to do the things the logs imply given
              # that the locking is definitely working and blocking anything
              # other than one transaction at a time from working on a set of
              # rows scoped by a particular resource UUID.
              #
              # In such a case, retry. But only do so once; then give up.
              #
              if retry_operation == false && exception.message.downcase.include?( 'deadlock' )
                retry_operation = true

                # Give other Threads time to run, maximising chance of deadlock
                # being resolved before retry.
                #
                sleep 0.1

              else
                raise exception

              end

            end # "begin"..."rescue"..."end"
          end while ( retry_operation ) # "begin"..."end while"

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
