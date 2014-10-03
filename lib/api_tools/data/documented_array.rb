########################################################################
# File::    documented_array.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Data::DocumentedObject DSL field implementation
#           allowing for documented Types references. Instantiated via
#           ApiTools::Data::DocumentedObject#array.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools
  module Data

    # As ApiTools::Presenters::Array but providing extended DSL facilities for
    # the Platform API documented Types and Resources collection.
    #
    class DocumentedArray < ApiTools::Presenters::Array
      include ApiTools::Data::DocumentedDSL
    end
  end
end
