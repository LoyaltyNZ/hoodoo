########################################################################
# File::    documented_object.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Presenters::Object DSL extension used to allow a
#           class to describe a well defined, documented Type or
#           Resource which may refer to another documented Type. Such
#           classes can then be used for JSON validation.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # Common data definitions and descriptions - describe, through a DSL, the
  # *representations* of Types and Resources documented in the Loyalty Platform
  # API.
  #
  # These descriptions omit common fields like "kind" or "created_at", as those
  # are implicit for any resource. Since resource representations are things
  # returned by services, the definitions are used for automatic validation of
  # service responses, not for validation of data sent in requests. That's done
  # via the DSL available to ApiTools::ServiceInterface subclasses, e.g.
  # ApiTools::ServiceInterface#to_create.
  #
  module Data

    # Extends the schema description DSL provided by
    # ApiTools::Presenters::Object with extra methods which are appropriate
    # for declarations of both Resources and Types described by the Loyalty
    # Platform API documentation.
    #
    class DocumentedObject < ApiTools::Presenters::Object

      include ApiTools::Data::DocumentedDSL

      # Does this instance state that it requires internationalisation?
      # If so +true+, else +false+.
      #
      def is_internationalised
        @internationalised == true
      end

    end
  end
end
