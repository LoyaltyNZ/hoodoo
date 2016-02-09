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
    module ManuallyDated

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::ManuallyDated
      #       # ...
      #     end
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

        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
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
        # _if_ not already set. The record's +primary_id+ primary key is set to
        # the value of +id+ concatenated by a new secondary UUID to form a 64
        # character unique value, again _if_ this is not already set.
        #
        def manual_dating_enabled
          self.nz_co_loyalty_hoodoo_manually_dated = true

          before_save do
            now = Time.now.utc

            self.created_at      ||= now
            self.updated_at      ||= now
            self.effective_start ||= self.created_at
            self.primary_id      ||= "#{ self.id }#{ Hoodoo::UUID.generate() }"
          end
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
                                      scope:      self.acquisition_scope( ident ) )

          return self.transaction do

            locked_rows = scope.lock()
            original    = scope.manually_dated_contemporary().acquire( ident )

            break if original.nil?

            # Set the end date on the "newest" record to mark it as a historic
            # entry. We never expect this to fail; if it did, an exception is
            # likely even without the "!" form of the method, but use this
            # explicitly and document clearly that an exception may arise.
            #
            original.effective_end = Time.now.utc
            original.save!

            # When you 'dup' a live model, ActiveRecord clears the 'created_at'
            # and 'updated_at' values, and the 'id' column - even if you set
            # the "primary_key=..." value on the model to something else. Put
            # it all back together again.
            #
            # Duplicate, apply attributes, then overwrite anything that is
            # vital for dating so that the inbound attributes hash can't cause
            # any inconsistencies.
            #
            updated = original.dup
            updated.assign_attributes( attributes )

            updated.id              = original.id
            updated.created_at      = original.created_at
            updated.updated_at      = original.effective_end # (sic.)
            updated.effective_start = original.effective_end # (sic.)
            updated.effective_end   = nil

            # Let the before_save filter create the primary ID (the real
            # primary key, as far as the database goes).
            #
            updated.primary_id = nil

            # This time, save with validation but no exceptions. The caller
            # examines the returned object to see if there are validation
            # errors / no persistence.
            #
            updated.save

            # The evaluated result of the transaction block must be 'updated'
            # in order for the method's return value to be as documented.
            #
            updated

          end
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
        # chain destruction do not apply. Callbacks related to _updating_
        # will be triggered, bceause that's the only thing happening "under
        # the hood".
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
                                           scope: self.acquisition_scope( ident ) )

          # See #manually_dated_update_in for rationale.
          #
          return self.transaction do

            locked_rows = scope.lock()
            record      = scope.manually_dated_contemporary().acquire( ident )

            break if record.nil?

            record.effective_end = Time.now.utc
            record.save!

            record

          end
        end

      end
    end
  end
end
