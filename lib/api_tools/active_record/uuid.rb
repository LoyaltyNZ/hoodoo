########################################################################
# File::    uuid.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing UUID management.
# ----------------------------------------------------------------------
#           17-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # automatic UUID management. See:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    # By including this module, a +before_validation+ filter is set up which
    # assigns a UUID if none is currently set (+id+ is +nil+).
    #
    # *IMPORTANT:* See ApiTools::ActiveRecord::UUID::included for important
    # information about database requirements / table creation when using
    # this mixin.
    #
    module UUID

      # When included in an ActiveRecord::Base subclass, this mixin:
      #
      # - Declares 'id' as the primary key
      # - Self-assigns a UUID to 'id' via +before_validation+ and
      #   ApiTools::UUID::generate
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include ApiTools::ActiveRecord::UUID
      #       # ...
      #     end
      #
      # The model *MUST* define its database representation in migrations so
      # that +id+ is a string based primary key. That means creating the table
      # with option <tt>:id => false</tt> and calling +#add_index+ afterwards to
      # properly declare the ID field as a unique primary key.
      #
      # Example:
      #
      #     create_table :model_table_name, :id => false do | t |
      #       t.string :id, :limit => 32, :null => false
      #     end
      #
      #     add_index :model_table_name, :id, :unique => true
      #
      def self.included( model )

        model.primary_key = 'id'

        model.before_validation do
          self.id = ApiTools::UUID.generate if self.id.nil?
        end

      end

    end
  end
end
