########################################################################
# File::    dated.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing as-per-API-standard internationalisation support.
# ----------------------------------------------------------------------
#           14-Jul-2015 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # as-per-API-standard internationalisation support. See
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
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Dated::included.
      #
      module ClassMethods

        # TODO: Placeholder
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def dated( context )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          return prevailing_scope
        end

        # TODO: Placeholder
        #
        # +date_time+:: The Date/Time (as a Ruby Date, Time or DateTime
        #               instance) for which the "effective dated" scope is to
        #               be constructed.
        #
        def dated_at( date_time )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          return prevailing_scope
        end

        # def dated_with( map )
        #   class_variable_set( '@@nz_co_loyalty_hoodoo_dated_with', map )
        # end
      end
    end
  end
end
