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
      # when needed, if you want the set of mixins, just define a model
      # which subclasses from this Hoodoo::ActiveRecord::Base class
      # instead of ActiveRecord::Base.
      #
      # This will include:
      #
      # * Hoodoo::ActiveRecord::Secure
      # * Hoodoo::ActiveRecord::Dated
      # * Hoodoo::ActiveRecord::Translated
      # * Hoodoo::ActiveRecord::Finder
      # * Hoodoo::ActiveRecord::UUID
      # * Hoodoo::ActiveRecord::Creator
      # * Hoodoo::ActiveRecord::Writer
      # * Hoodoo::ActiveRecord::ErrorMapping
      #
      class Base < ::ActiveRecord::Base

        # Reading data.
        #
        include Hoodoo::ActiveRecord::Secure
        include Hoodoo::ActiveRecord::Dated
        include Hoodoo::ActiveRecord::Translated
        include Hoodoo::ActiveRecord::Finder

        # Writing data.
        #
        include Hoodoo::ActiveRecord::UUID
        include Hoodoo::ActiveRecord::Creator
        include Hoodoo::ActiveRecord::Writer

        # Other features.
        #
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

          Hoodoo::ActiveRecord::Secure.instantiate( model )
          Hoodoo::ActiveRecord::Dated.instantiate( model )
          Hoodoo::ActiveRecord::Translated.instantiate( model )
          Hoodoo::ActiveRecord::Finder.instantiate( model )

          Hoodoo::ActiveRecord::UUID.instantiate( model )
          Hoodoo::ActiveRecord::Creator.instantiate( model )
          Hoodoo::ActiveRecord::Writer.instantiate( model )

          super( model )

        end
      end

    rescue LoadError
    end

  end
end
