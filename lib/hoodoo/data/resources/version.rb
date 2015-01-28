########################################################################
# File::    version.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Version'.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Version'. This is an
      # example that ties in with the example Version Service.
      #
      class Version < Hoodoo::Presenters::Base

        schema do
          integer :major, :required => true
          integer :minor, :required => true
          integer :patch, :required => true
        end

      end
    end
  end
end
