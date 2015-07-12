########################################################################
# File::    mass_tag_event.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Resource 'MassTagEvent'.
# ----------------------------------------------------------------------
#           12-Jun-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'MassTagEvent'.
      #
      class MassTagEvent < Hoodoo::Presenters::Base

        # Defined values for the +tagging_action+ enumeration in the schema.
        #
        ACTIONS = [ :add, :replace, :remove ]

        schema do
          text  :resource_kind,        :required => true
          array :resource_identifiers, :required => true
          enum  :tagging_action,       :required => true, :from => ACTIONS
          array :tag_ids,              :required => true
        end

      end
    end
  end
end
