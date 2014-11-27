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
    # assigns a UUID if none is currently set (+id+ is +nil+). It also
    # defines validations to ensure the +id+ is present, unique and a valid
    # UUID.
    #
    # *IMPORTANT:* See ApiTools::ActiveRecord::UUID::included for important
    # information about database requirements / table creation when using
    # this mixin.
    #
    module UUID

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include ApiTools::ActiveRecord::UUID
      #       # ...
      #     end
      #
      def self.included( model )

        instantiate( model ) unless model == ApiTools::ActiveRecord::Base

      end

      # When called, this method:
      #
      # - Declares 'id' as the primary key
      # - Self-assigns a UUID to 'id' via +before_validation+ and
      #   ApiTools::UUID::generate
      # - Adds validations to 'id' to ensure it is present, unique and a valid
      #   UUID.
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
      def self.instantiate( model )

        model.primary_key = 'id'

        model.before_validation do
          self.id = ApiTools::UUID.generate if self.id.nil?
        end

        model.validates :id, uuid: true, presence: true, uniqueness: true

      end

    end
  end
end
