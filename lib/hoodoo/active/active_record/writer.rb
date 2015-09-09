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
    # a...

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
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        unless model == Hoodoo::ActiveRecord::Base
          model.send( :include, Hoodoo::ActiveRecord::Writer )
          instantiate( model )
        end

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

      def self.persist_in( context, attributes = {}, options = {} )
        instance = self.new( attributes )

        if block_given?
          yield( instance )
        end

        # (maybe with locking, do...)

        instance.save # <-- somewhere in here, we handle the duplicates case
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Writer::included.
      #
      module ClassMethods
      end
    end
  end
end
