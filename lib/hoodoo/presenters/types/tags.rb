########################################################################
# File::    tags.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Hoodoo::Presenters::BaseDSL field implementation
#           which supports a field defined to contain a string of
#           comma separated tags.
# ----------------------------------------------------------------------
#           30-Sep-2014 (ADH): Created.
#           31-Oct-2014 (ADH): Moved to generic presenter layer from
#                              documented data layer.
########################################################################

module Hoodoo
  module Presenters

    # A JSON string-like schema member intended to hold tag data.
    #
    class Tags < Hoodoo::Presenters::Text
      # TODO: Note inheritance from "...::Text" not "...::Field"
      # TODO: Future validations to ensure string looks tag-like?
    end
  end
end
