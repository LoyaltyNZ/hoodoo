########################################################################
# File::    base.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include all mixins.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    begin
      require 'active_record'

      # While individual ActiveRecord mixins can be included as and
      # when needed, if you want everything, just define a model which
      # subclasses from this Hoodoo::ActiveRecord::Base class instead
      # of ActiveRecord::Base.
      #
      class Base < ::ActiveRecord::Base

        include Hoodoo::ActiveRecord::UUID
        include Hoodoo::ActiveRecord::Dated
        include Hoodoo::ActiveRecord::Secure
        include Hoodoo::ActiveRecord::Translated
        include Hoodoo::ActiveRecord::Finder
        include Hoodoo::ActiveRecord::ErrorMapping

        # Tells ActiveRecord this is not a model that is persisted.
        #
        self.abstract_class = true

        # Instantiates all the ActiveRecord mixins when this class is
        # inherited.
        #
        # +model+:: The ActiveRecord::Base descendant that is including
        #           this module.
        #
        def self.inherited( model )

          Hoodoo::ActiveRecord::UUID.instantiate( model )
          Hoodoo::ActiveRecord::Dated.instantiate( model )
          Hoodoo::ActiveRecord::Secure.instantiate( model )
          Hoodoo::ActiveRecord::Translated.instantiate( model )
          Hoodoo::ActiveRecord::Finder.instantiate( model )

          super

        end
      end

    rescue LoadError
    end

  end
end
