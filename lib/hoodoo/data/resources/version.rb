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

    # Module used as a namespace to collect classes that represent
    # Resources documented by the your platform's API. Each is an
    # Hoodoo::Presenters::Base subclass, so can be used to render
    # and validate JSON data.
    #
    # Hoodoo::Data::Resources::Version is defined as an example
    # class. The Hoodoo::Data::Resources::* namespace is otherwise
    # free for use by Hoodoo clients (indeed, types or resources
    # that wish to reference one another through the DSL *must*
    # use this namespace).
    #
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