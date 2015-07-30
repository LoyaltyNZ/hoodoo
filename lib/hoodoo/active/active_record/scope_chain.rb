########################################################################
# File::    scope_chain.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Plug-in style automatic scoping for things like the Finder
#           methods.
# ----------------------------------------------------------------------
#           29-Jul-2015 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Mixin for models subclassed from ActiveRecord::Base providing support
    # methods to handle automatic context-based query scoping. See
    # Hoodoo::ActiveRecord::ScopeChain::ClassMethods#scope_chain_with for full
    # details.
    #
    # This is usually only used via Hoodoo::ActiveRecord::Finder (and is
    # included by that code automatically) but can be used stand-alone if you
    # want the scoping facilities _without_ the Finder code present. Bear in
    # mind that it operates on a class-wide basis so you only get one
    #
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module ScopeChain

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::ScopeChain
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
      # Hoodoo::ActiveRecord::ScopeChain::ClassMethods methods are defined
      # as class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::ScopeChain::included.
      #
      module ClassMethods

        # This method provides a route for automatically "plugging in" a set of
        # mixins which will cooperate to provide a combined query scope when the
        # #scope_chain_in


        def scope_chain_with( options )
          scope_chain = class_variable_defined?( :@@nz_co_loyalty_hoodoo_scope_chain ) ?
                             class_variable_get( :@@nz_co_loyalty_hoodoo_scope_chain ) :
                             []

          modules = options[ :modules ]

          if modules.nil?
            raise "Hoodoo::ActiveRecord::ScopeChain#scope_chain_with requires a value for the ':modules' options key"
          elsif modules.is_a?( ::Array ) == false
            raise "Hoodoo::ActiveRecord::ScopeChain#scope_chain_with given unexpected class '#{ modules.class.name }' as a value for ':modules' options key"
          end

          case options[ :position ]
            when :replace
              scope_chain = modules.dup
            when :beginning
              scope_chain.unshift( *modules )
            else # :end, nil, or otherwise unrecognised
              scope_chain.push( *modules )
          end

          scope_chain.each do | module |
            include module[ :module ]
          end

          @@nz_co_loyalty_hoodoo_scope_chain = scope_chain
        end



        def scope_chain_in( context )
          scope       = all() # "Model.all" -> returns anonymous scope
          scope_chain = class_variable_defined?( :@@nz_co_loyalty_hoodoo_scope_chain ) ?
                             class_variable_get( :@@nz_co_loyalty_hoodoo_scope_chain ) :
                             []

          scope_chain.each do | module |
            scope = scope.send( module[ :method ] )
          end

          return scope
        end
      end
    end
  end
end
