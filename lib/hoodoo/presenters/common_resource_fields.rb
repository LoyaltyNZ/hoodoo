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
        text     :kind,       :required => true
        text     :language
      end
    end
  end
end
