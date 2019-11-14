########################################################################
# File::    common_resource_fields.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define a schema describing fields common to any schema that
#           describes an API Resource.
# ----------------------------------------------------------------------
#           02-Dec-2014 (ADH): Split from DocumentedPresenter.
########################################################################

module Hoodoo
  module Presenters

    # Used internally for additional validation of common Resource fields.
    # See Hoodoo::Presenters::Base::validate.
    #
    class CommonResourceFields < Hoodoo::Presenters::Base
      schema do
        uuid     :id,         :required => true
        datetime :created_at, :required => true
        datetime :updated_at, :required => false
        text     :kind,       :required => true
        text     :language

        hash     :secured_with

        hash     :_embed
        hash     :_reference
      end
    end
  end
end
