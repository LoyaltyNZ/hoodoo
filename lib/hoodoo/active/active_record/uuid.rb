########################################################################
# File::    uuid.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing UUID management.
# ----------------------------------------------------------------------
#           17-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # automatic UUID management. See:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    # By including this module, an on-create validation is added to the
    # including model which assigns a UUID if none is currently set (+id+
    # is +nil+). It also adds validations to ensure the +id+ is present,
    # unique and a valid UUID. You should always make sure that there are
    # accompanying database-level uniqueness and non-null constraints on
    # the relevant table's `id` column, too.
    #
    # *IMPORTANT:* See Hoodoo::ActiveRecord::UUID::included for important
    # information about database requirements / table creation when using
    # this mixin.
    #
    module UUID

      # Instantiates this module when it is included.
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::UUID
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

      # When called, this method:
      #
      # - Declares 'id' as the primary key
      # - Self-assigns a UUID to 'id' via an on-create validation
      # - Adds validations to 'id' to ensure it is present, unique and a valid
      #   UUID.
      #
      # The model *MUST* define its database representation in migrations so
      # that +id+ is a string based primary key, as follows:
      #
      #     create_table :model_table_name, :id => :string do | t |
      #       # ...your normal column definitions go here...
      #     end
      #
      #     change_column :model_table_name, :id, :string, :limit => 32
      #
      # +model+:: The ActiveRecord::Base descendant class that is including
      #           this module.
      #
      def self.instantiate( model )
        model.primary_key = 'id'

        model.validate( :on => :create ) do
          self.id ||= Hoodoo::UUID.generate()
        end

        model.validates(
          :id,
          {
            :uuid       => true,
            :presence   => true,
            :uniqueness => true
          }
        )
      end

    end
  end
end
