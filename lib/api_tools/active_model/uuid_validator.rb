########################################################################
# File::    uuid_validator.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: UUID validator for models.
#
# ----------------------------------------------------------------------
#           26-Nov-2014 (RJS): Created.
########################################################################

if defined?( ActiveModel ) && defined?( ActiveModel::EachValidator )
  class UuidValidator < ActiveModel::EachValidator

    # Provides simple UUID validation via an ActiveModel::EachValidator. Any
    # field it is applied to will be considered valid if it is +nil+ or not a
    # valid UUID. In the case of UUIDs which should not be nil, a separate
    # validation must be added.
    #
    # Example:
    #
    #     class SomeModel < ActiveRecord::Base
    #       include ApiTools::ActiveRecord::UUID
    #
    #       validates :somefield, uuid: true
    #     end
    #
    def validate_each( record, attribute, value )

      unless value.nil? || ApiTools::UUID.valid?( value )
        record.errors[attribute] << ( options[:message] || "is invalid" )
      end

    end
  end
end
