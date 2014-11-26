########################################################################
# File::    base.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include all mixins.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module ActiveRecord

    begin
      require 'active_record'

      # While individual ActiveRecord mixins can be included as and when needed,
      # if you want everything, just define a model which subclasses from this
      # ApiTools::ActiveRecord::Base class instead of ActiveRecord::Base.
      #
      class Base < ::ActiveRecord::Base
        include ApiTools::ActiveRecord::UUID
        include ApiTools::ActiveRecord::Finder
        include ApiTools::ActiveRecord::ErrorMapping
      end

    rescue LoadError
    end

  end
end
