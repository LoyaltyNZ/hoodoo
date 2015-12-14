########################################################################
# File::    creator.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing context-aware model instance creation, allowing
#           service authors to auto-inherit related features from Hoodoo
#           without changing their code.
# ----------------------------------------------------------------------
#           07-Dec-2015 (ADH): Created as a proper place for "new_in",
#                              which had historically and confusingly
#                              resided inside the Finder mixin.
########################################################################

module Hoodoo

  # Support mixins for models subclassed from ActiveRecord::Base. See:
  #
  # * http://guides.rubyonrails.org/active_record_basics.html
  #
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # context-aware model instance creation, allowing service authors to
    # auto-inherit related features from Hoodoo without changing their code.
    #
    # It is _STRONGLY_ _RECOMMENDED_ that you use the likes of:
    #
    # * Hoodoo::ActiveRecord::Creator::ClassMethods::new_in
    #
    # ...to create model instances and participate "for free" in whatever
    # plug-in ActiveRecord modules are mixed into the model classes, such as
    # Hoodoo::ActiveRecord::Dated.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Creator

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Creator
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
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

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Creator::included.
      #
      module ClassMethods

        # Create an instance of this model with knowledge of the wider request
        # context. This may lead to important things like support of inbound
        # "dated_from" values, depending upon the Hoodoo mixins included (or
        # not) by this class - see Hoodoo::ActiveRecord::Dated.
        #
        # You use this exactly as you would for ActiveRecord::Core#new, but an
        # additional, mandatory first parameter providing the request context
        # must be supplied. For example, instead of this:
        #
        #     instance = SomeActiveRecordSubclass.new( attrs )
        #
        # ...do this inside a resource implementation:
        #
        #     instance = SomeActiveRecordSubclass.new_in( context, attrs )
        #
        # See also:
        #
        # * http://api.rubyonrails.org/classes/ActiveRecord/Base.html
        #
        # Parameters:
        #
        # +context+::    Hoodoo::Services::Context instance describing a call
        #                context. This is typically a value passed to one of
        #                the Hoodoo::Services::Implementation instance methods
        #                that a resource subclass implements.
        #
        # +attributes+:: Optional model attributes Hash, passed through to
        #                ActiveRecord::Core#new.
        #
        # &block::       Optional block for initialisation, passed through to
        #                ActiveRecord::Core#new.
        #
        # Returns a new model instance which may have context-derived values
        # set for some attributes, in addition to anything set through the
        # +attributes+ or <tt>&block</tt> parameters, if present.
        #
        # Note that context-dependent data is set _AFTER_ attribute or block
        # based values, so takes precedence over anything you might set up
        # using those parameters.
        #
        def new_in( context, attributes = nil, &block )

          instance = self.new( attributes, &block )

          # TODO: Refactor this to use the scope chain plugin approach in due
          #       course, but for now, pragmatic implementation does the only
          #       thing we currently need to do - set "created_at".
          #
          if self.include?( Hoodoo::ActiveRecord::Dated )
            unless context.request.dated_from.nil?
              instance.created_at = instance.updated_at = context.request.dated_from
            end
          end

          return instance
        end

      end
    end
  end
end
