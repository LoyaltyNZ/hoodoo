########################################################################
# File::    documented_tags.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Data::DocumentedObject DSL field implementation
#           which supports a field defined to contain a string of
#           comma separated tags.
# ----------------------------------------------------------------------
#           30-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    # A JSON UUID schema member
    class DocumentedTags < ApiTools::Presenters::Text
      # TODO: Note inheritance from "...::Text" not "...::Field"
      # TODO: Future validations to ensure string looks tag-like?
    end
  end
end
