########################################################################
# File::    error_primitive.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'ErrorPrimitive'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data

    # Module used as a namespace to collect classes that represent Types
    # documented by your platform's API. Each is an
    # Hoodoo::Presenters::Base subclass, so can be used to render
    # and validate JSON data.
    #
    module Types

      # Documented Platform API Type 'ErrorPrimitive'.
      #
      class ErrorPrimitive < Hoodoo::Presenters::Base

        schema do
          text :code,     :required => true
          text :message,  :required => true
          text :reference
        end

      end
    end
  end
end
