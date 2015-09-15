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
    module Writer

      # Instantiates this module when it is included:
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
        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
        super( model )
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Writer::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Writer::included.
      #
      module ClassMethods

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
        # Example:
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
        #
        #       model_instance = Unique.persist_in( context, attributes )
        #       return if context.response.halt_processing?
        #
        #       # ...any other processing...
        #
        #       context.response.set_resource( rendering_of( context, model_instance ) )
        #     end
        #
        # Parameters:
        #
        # +context+::    Hoodoo::Services::Context instance describing a call
        #                context. This is typically a value passed to one of
        #                the Hoodoo::Services::Implementation instance methods
        #                that a resource subclass implements.
        #
        # +attributes+:: Attributes hash to be passed to this model class's
        #                constructor, via <tt>self.new( attributes )</tt>.
        #                Optional. If omitted, pass the +instance+ parameter
        #                instead.
        #
        # +instance+::   An instance of this model which is fully initialised
        #                and ready to be persisted (saved). Optional. If
        #                omitted, pass the +attributes+ parameter instead.
        #
        def persist_in( context, attributes: nil, instance: nil )

          # We either get a ready-initialised instance in the 'instance'
          # parameter or have to bulid one from the 'attributes' parameter,
          # which takes precedence.

          instance = self.new( attributes ) unless attributes.nil?

          # If this model has an ActiveRecord uniqueness validation, it is
          # still subject to race conditions and MUST be backed by a database
          # constraint. If this constraint fails, try to re-run model
          # validations just in case it was a race condition case; though of
          # course, it could be that there is *only* a database constraint and
          # no model validation. If there is *only* a model validation, the
          # model is ill-defined and at risk.

          # First just see if we have any problems saving anyway.
          #
          errors_occurred = begin
            :any unless instance.save
          rescue ::ActiveRecord::RecordNotUnique => error
            :duplication
          end

          # If there was a problem, just try adding model-originated mapped
          # errors via the relevant mixin. If there are no errors in context,
          # add one for the invalid duplication case - no AR-level uniqueness
          # validations must exist on the model.
          #
          unless errors_occurred.nil?
            context.response.add_errors( instance.platform_errors() ) if instance.respond_to?( :platform_errors )

            # We do nothing else. Hoodoo will check for errors on exit and if
            # it "sees" only generic.invalid_duplication errors, plus an
            # inbound flag saying that the caller is allowing these, it'll
            # transform the response into a 204. If it sees any other errors,
            # normal processing happens. At the time of writing, this is
            # inside "middleware.rb" in method
            # "remove_expected_errors_when_experiencing_deja_vu", though this
            # may get changed without the comment here being updated too.
            #
            if errors_occurred == :duplication && context.response.halt_processing? == false
              context.response.add_error(
                'generic.invalid_duplication',
                {
                  :message   => 'Cannot create this resource instance due to a uniqueness constraint violation',
                  :reference => { :field_name => 'unknown' }
                }
              )
            end
          end

          return instance
        end

      end
    end
  end
end
