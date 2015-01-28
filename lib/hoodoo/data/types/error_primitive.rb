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
