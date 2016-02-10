########################################################################
# File::    writer.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing context-aware data writing, allowing service
#           authors to auto-inherit persistence-related features from
#           Hoodoo without changing their code.
# ----------------------------------------------------------------------
#           31-Aug-2015 (ADH): Created.
########################################################################

module Hoodoo

  # Support mixins for models subclassed from ActiveRecord::Base. See:
  #
  # * http://guides.rubyonrails.org/active_record_basics.html
  #
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # context-aware data writing, allowing service authors to auto-inherit
    # persistence-related features from Hoodoo without changing their own
    # code.
    #
    # See individual module methods for examples, along with:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    # Dependency Hoodoo::ActiveRecord::ErrorMapping is also included
    # automatically.
    #
    module Writer

      # Instantiates this module when it is included.
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Writer
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant class that is including
      #           this module.
      #
      def self.included( model )
        unless model == Hoodoo::ActiveRecord::Base
          model.send( :include, Hoodoo::ActiveRecord::ErrorMapping )
          instantiate( model )
        end

        super( model )
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Writer::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # This module depends upon Hoodoo::ActiveRecord::ErrorMapping, so
      # that will be auto-included first if it isn't already.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        # See instance method "persist_in" for how this gets used.
        #
        model.validate do
          if @nz_co_loyalty_hoodoo_writer_db_uniqueness_violation == true
            errors.add( :base, 'has already been taken' )
          end
        end
      end

      # Instance equivalent of
      # Hoodoo::ActiveRecord::Writer::ClassMethods.persist_in - see that for
      # details. The class method just calls here, having constructed an
      # instance based on the attributes it was given. If you have already
      # built an instance yourself, just call this instance method equivalent
      # instead.
      #
      # As an instance-based method, the return value and error handling
      # semantics differ from the class-based counterpart. Instead of
      # checking "persisted?", check the return value of +persist_in+. This
      # means you can also use +persist_in+ to save a previousl persisted, but
      # now updated record, should you so wish.
      #
      #     def create( context )
      #       attributes = mapping_of( context.request.body )
      #       model_instance = Unique.new( attributes )
      #
      #       # ...maybe make other changes to model_instance, then...
      #
      #       unless model_instance.persist_in( context ) === :success
      #
      #         # Error condition. If you're using the error handler mixin
      #         # in Hoodoo::ActiveRecord::ErrorMapping, do this:
      #         #
      #         context.response.add_errors( model_instance.platform_errors )
      #         return # Early exit
      #
      #       end
      #
      #       # ...any other processing...
      #
      #       context.response.set_resource( rendering_of( context, model_instance ) )
      #     end
      #
      # Parameters:
      #
      # +context+:: Hoodoo::Services::Context instance describing a call
      #             context. This is typically a value passed to one of
      #             the Hoodoo::Services::Implementation instance methods
      #             that a resource subclass implements.
      #
      # Returns a Symbol of +:success+ or +:failure+ indicating the outcome
      # of the same attempt. In the event of failure, the model will be
      # invalid and not persisted; you can read errors immediately and should
      # avoid unnecessarily re-running validations by calling +valid?+ or
      # +validate+ on the instance.
      #
      def persist_in( context )

        # If this model has an ActiveRecord uniqueness validation, it is
        # still subject to race conditions and MUST be backed by a database
        # constraint. If this constraint fails, try to re-run model
        # validations just in case it was a race condition case; though of
        # course, it could be that there is *only* a database constraint and
        # no model validation. If there is *only* a model validation, the
        # model is ill-defined and at risk.

        # TODO: This flag is nasty but seems unavoidable. Whenever you query
        #       the validity of a record, AR will always clear all errors and
        #       then (re-)run validations. We cannot just add an error to
        #       "base" and expect it to survive. Instead, it's necessary to
        #       use this flag to signal to the custom validator added in the
        #       'self.instantiate' implementation earlier that it should add
        #       an error. Trouble is, when do we clear the flag...?
        #
        #       This solution works but is inelegant and fragile.
        #
        @nz_co_loyalty_hoodoo_writer_db_uniqueness_violation = false

        # First just see if we have any problems saving anyway.
        #
        errors_occurred = begin
          self.transaction( :requires_new => true ) do
            :any unless self.save
          end
        rescue ::ActiveRecord::RecordNotUnique => error
          :duplication
        end

        # If an exception caught a duplication violation then either there is
        # a race condition on an AR-level uniqueness validation, or no such
        # validation at all. Thus, re-run validations with "valid?" and if it
        # still seems OK we must be dealing with a database-only constraint.
        # Set the magic flag (ugh, see earlier) to signal that when
        # validations run, they should add a relevant error to "base".
        #
        if errors_occurred == :duplication
          if self.valid?
            @nz_co_loyalty_hoodoo_writer_db_uniqueness_violation = true
            self.validate
          end
        end

        return errors_occurred.nil? ? :success : :failure
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Writer::included.
      #
      module ClassMethods

        # == Overview
        #
        # Service authors _SHOULD_ use this method when persisting data with
        # ActiveRecord if there is a risk of duplication constraint violation
        # of any kind. This will include a violation on the UUID of a resource
        # if you support external setting of this value via the body of a
        # +create+ call containing the +id+ field, injected by Hoodoo as the
        # result of an authorised use of the <tt>X-Resource-UUID</tt> HTTP
        # header.
        #
        # Services often run in highly concurrent environments and uniqueness
        # constraint validations with ActiveRecord cannot protect against
        # race conditions in such cases. IT works at the application level;
        # the check to see if a record exists with a duplicate value in some
        # given column is a separate operation from that which stores the
        # record subsequently. As per the Rails Guides entry on the uniqueness
        # validation at the time of writing:
        #
        # http://guides.rubyonrails.org/active_record_validations.html#uniqueness
        #
        # <i>"It does not create a uniqueness constraint in the database, so
        # it may happen that two different database connections create two
        # records with the same value for a column that you intend to be
        # unique. To avoid that, you must create a unique index on both
        # columns in your database."</i>
        #
        # You *MUST* always use a uniqueness constraint at the database level
        # and *MAY* additionally use ActiveRecord validations for a higher
        # level warning in all but race condition edge cases. If you then use
        # this +persist_in+ method to store records, all duplication cases
        # will be handled elegantly and reported as a
        # <tt>generic.invalid_duplication</tt> error. In the event that a
        # caller has used the <tt>X-Deja-Vu</tt> HTTP header, Hoodoo will take
        # such an error and transform it into a non-error 204 HTTP response;
        # so by using +persist_in+, you also ensure that your service
        # participates successfully in this process without any additional
        # coding effort. You get safe concurrency and protection against the
        # inherent lack of idempotency in HTTP +POST+ operations via any
        # must-be-unique fields (within your defined scope) automatically.
        #
        # Using this method for data storage instead of plain ActiveRecord
        # +send+ or <tt>send!</tt> will also help your code auto-inherit any
        # additional future write-related enhancements in Hoodoo should they
        # arise, without necessarily needing service code changes.
        #
        #
        # == Example
        #
        #     class Unique < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Writer
        #       validates :unique_code, :presence => true, :uniqueness => true
        #     end
        #
        # The migration to create the table for the Unique model _MUST_ have a
        # uniqueness constraint on the +unique_code+ field, e.g.:
        #
        #     def change
        #       add_column :uniques, :unique_code, :null => false
        #       add_index :uniques, [ :unique_code ], :unique => true
        #     end
        #
        # Then, inside the implementation class which uses the above model,
        # where you have (say) written private methods +mapping_of+ which
        # maps +context.request.body+ to an attributes Hash for persistence
        # and +rendering_of+ which uses Hoodoo::Presenters::Base.render_in to
        # properly render a representation of your resource, you would write:
        #
        #     def create( context )
        #       attributes = mapping_of( context.request.body )
        #       model_instance = Unique.persist_in( context, attributes )
        #
        #       unless model_instance.persisted?
        #
        #         # Error condition. If you're using the error handler mixin
        #         # in Hoodoo::ActiveRecord::ErrorMapping, do this:
        #         #
        #         context.response.add_errors( model_instance.platform_errors )
        #         return # Early exit
        #
        #       end
        #
        #       # ...any other processing...
        #
        #       context.response.set_resource( rendering_of( context, model_instance ) )
        #     end
        #
        #
        # == Parameters
        #
        # +context+::    Hoodoo::Services::Context instance describing a call
        #                context. This is typically a value passed to one of
        #                the Hoodoo::Services::Implementation instance methods
        #                that a resource subclass implements.
        #
        # +attributes+:: Attributes hash to be passed to this model class's
        #                constructor, via <tt>self.new( attributes )</tt>.
        #
        # See also the Hoodoo::ActiveRecord::Writer#persist_in instance method
        # equivalent of this class method.
        #
        #
        # == Nested transaction note
        #
        # Ordinarily an exception in a nested transaction does not roll back.
        # ActiveRecord wraps all saves in a transaction "out of the box", so
        # the following construct could have unexpected results...
        #
        #     Model.transaction do
        #       instance.persist_in( context )
        #     end
        #
        # ...if <tt>instance.valid?</tt> runs any SQL queries - which is very
        # likely. PostgreSQL, for example, would then raise an exception; the
        # inner transaction failed, leaving the outer one in an aborted state:
        #
        #     PG::InFailedSqlTransaction: ERROR:  current transaction is
        #     aborted, commands ignored until end of transaction block
        #
        # ActiveRecord provides us with a way to define a transaction that
        # does roll back via the <tt>requires_new: true</tt> option. Hoodoo
        # thus protects callers from the above artefacts by ensuring that all
        # saves are wrapped in an outer transaction that causes rollback in
        # any parents. This sidesteps the unexpected behaviour, but service
        # authors might sometimes need to be aware of this if using complex
        # transaction behaviour along with <tt>persist_in</tt>.
        #
        # In pseudocode, the internal implementation is:
        #
        #     self.transaction( :requires_new => true ) do
        #       self.save
        #     end
        #
        def persist_in( context, attributes )
          instance = self.new( attributes )
          instance.persist_in( context )

          return instance
        end

      end
    end
  end
end
