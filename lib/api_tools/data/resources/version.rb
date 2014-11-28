########################################################################
# File::    version.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Version'.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # Module used as a namespace to collect classes that represent Resources
    # documented by the your platform's API. Each is an
    # ApiTools::Data::DocumentedPresenter subclass, so can be used to render
    # and validate JSON data.
    #
    module Resources

      # Documented Platform API Resource 'Version'.
      #
      class Version < ApiTools::Data::DocumentedPresenter

        schema do
          integer :major, :required => true
          integer :minor, :required => true
          integer :patch, :required => true
        end

      end
    end
  end
end
