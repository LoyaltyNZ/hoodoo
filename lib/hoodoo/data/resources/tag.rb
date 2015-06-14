########################################################################
# File::    tag.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Resource 'Tag'.
# ----------------------------------------------------------------------
#           5-Jun-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Tag'.
      #
      class Tag < Hoodoo::Presenters::Base

        schema do
          internationalised

          text  :name, :required => :true
        end

      end
    end
  end
end
