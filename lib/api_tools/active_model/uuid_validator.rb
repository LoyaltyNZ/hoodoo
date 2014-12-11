########################################################################
# File::    uuid_validator.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: UUID validator for models.
#
# ----------------------------------------------------------------------
#           26-Nov-2014 (RJS): Created.
########################################################################

module ApiTools
  module ActiveRecord
    begin
      require 'active_model'

      # Provides simple UUID validation via an ActiveModel::EachValidator.
      # Uuid is not capitalised as ActiveModel's "magic" cannot find the
      # validator if it is.
      #
      class ::UuidValidator < ::ActiveModel::EachValidator

        # Any field this validator is applied to is considered valid if it is
        # +nil+ or a valid UUID. In the case of UUIDs which should not be nil,
        # a separate validation must be added.
        #
        # Example:
        #
        #     class SomeModel < ActiveRecord::Base
        #
        #       validates :somefield, uuid: true
        #     end
        #
        def validate_each( record, attribute, value )

          unless value.nil? || ApiTools::UUID.valid?( value )
            record.errors[attribute] << ( options[ :message ] || "is invalid" )
          end

        end

      end
    rescue LoadError
    end
  end
end
