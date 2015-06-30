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
    # By including this module, a +before_validation+ filter is set up which
    # assigns a UUID if none is currently set (+id+ is +nil+). It also
    # defines validations to ensure the +id+ is present, unique and a valid
    # UUID.
    #
    # *IMPORTANT:* See Hoodoo::ActiveRecord::UUID::included for important
    # information about database requirements / table creation when using
    # this mixin.
    #
    module UUID

      # Instantiates this module when it is included:
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
      end

      # When called, this method:
      #
      # - Declares 'id' as the primary key
      # - Self-assigns a UUID to 'id' via +before_validation+ and
      #   Hoodoo::UUID::generate
      # - Adds validations to 'id' to ensure it is present, unique and a valid
      #   UUID.
      #
      # The model *MUST* define its database representation in migrations so
      # that +id+ is a string based primary key. That means creating the table
      # with option <tt>:id => false</tt> and calling +#add_index+ afterwards
      # to properly declare the ID field as a unique primary key.
      #
      # Example:
      #
      #     create_table :model_table_name, :id => false do | t |
      #       t.string :id, :limit => 32, :null => false
      #     end
      #
      #     add_index :model_table_name, :id, :unique => true
      #
      # +model+:: The ActiveRecord::Base descendant class that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )

        model.primary_key = 'id'

        model.before_validation do
          if self.send( self.class.uuid_column ).nil?
            self.send( "#{self.class.uuid_column}=", Hoodoo::UUID.generate() )
          end
        end

        model.validate do | instance |

          # Validator options
          v_opts = {
            :attributes => [ self.class.uuid_column ],
            :class => self.class
          }

          # Note that the unique UUID validator is conditionally added second
          # rather than last to maintain the legacy order of these validations
          # which some tests may rely on.
          validator_instances = [
            ::UuidValidator.new( v_opts.dup ),
            ::ActiveRecord::Validations::PresenceValidator.new( v_opts.dup )
          ]
          if instance.class.validate_uuid_uniqueness?
            validator_instances.insert( 1, ::ActiveRecord::Validations::UniquenessValidator.new( v_opts.dup ) )
          end

          validator_instances.each do | validator_instance |
            validator_instance.validate_each(
              self,
              self.class.uuid_column,
              self.send( self.class.uuid_column )
            )
          end

        end

      end

      module ClassMethods

        # The name of the column which stores the UUID. This can be set via
        # #uuid_column=, defaulting to :id.
        #
        def uuid_column
          if class_variable_defined?( :@@hoodoo_uuid_column )
            return class_variable_get( :@@hoodoo_uuid_column )
          else
            return :id
          end
        end

        # Set the name of the column which stores the uuid. This can be read via
        # #uuid_column, defaulting to :id.
        #
        # +uuid_column_name+:: The symbolised name of the column which holds the
        #                      UUID.
        #
        def uuid_column=( uuid_column_name )
          class_variable_set( :@@hoodoo_uuid_column, uuid_column_name )
        end

        # True if the UUID of the model should be validated to be unqiue. This
        # can be set via #validate_uuid_uniqueness=, defaulting to true.
        #
        def validate_uuid_uniqueness?
          if class_variable_defined?( :@@hoodoo_unique_uuid_column )
            return class_variable_get( :@@hoodoo_unique_uuid_column )
          else
            return true
          end
        end

        # Set whether the UUID of the model should be validated to be unique.
        # This can be checked via #validate_uuid_uniqueness? and defaults to
        # true.
        #
        # +is_unique+:: Boolean value, true if uuid column should be validated
        #               as unique.
        #
        def validate_uuid_uniqueness=( validate_uuid_uniqueness )
          class_variable_set( :@@hoodoo_unique_uuid_column, validate_uuid_uniqueness )
        end

      end

    end
  end
end
