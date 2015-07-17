########################################################################
# File::    translated.rb
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
    # Hoodoo::ActiveRecord::Translated::ClassMethods#translated for details.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Translated

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Translated
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
      # Hoodoo::ActiveRecord::Translated::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Translated::included.
      #
      module ClassMethods

        # TODO: Placeholder.
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def translated( context )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          return prevailing_scope
        end

        # def translated_with( map )
        #   class_variable_set( '@@nz_co_loyalty_hoodoo_translated_with', map )
        # end
      end
    end
  end
end
