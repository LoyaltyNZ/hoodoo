########################################################################
# File::    log_entry.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'LogEntry'.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'LogEntry'.
      #
      class LogEntry < ApiTools::Data::DocumentedPresenter

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
