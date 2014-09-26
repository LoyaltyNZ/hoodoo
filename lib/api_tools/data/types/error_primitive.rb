########################################################################
# File::    error_primitive.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'ErrorPrimitive'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # Module used as a namespace to collect classes that represent Types
    # documented by the Loyalty Platform API. Each can be instantiated and
    # used for JSON validation purposes - see
    # ApiTools::Data::DocumentedKind#initialize for details.
    #
    module Types

      # Documented Platform API Type 'ErrorPrimitive'.
      #
      class ErrorPrimitive < ApiTools::Data::DocumentedKind

        define do
          text :code, :required => true
          text :message, :required => true
          text :reference
        end

      end
    end
  end
end
