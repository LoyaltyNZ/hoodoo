########################################################################
# File::    log.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Log'.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
#           01-Dec-2014 (ADH): Renamed resource from LogEntry to Log.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Log'.
      #
      class Log < ApiTools::Data::DocumentedPresenter

        schema do
          text :level,     :required => true
          text :component, :required => true
          text :code,      :required => true

          uuid :interaction_id
          hash :data
        end

      end
    end
  end
end
