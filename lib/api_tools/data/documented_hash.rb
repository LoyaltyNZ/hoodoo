########################################################################
# File::    documented_hash.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: ApiTools::Data::DocumentedObject DSL field implementation
#           allowing for documented Types references. Instantiated via
#           ApiTools::Data::DocumentedObject#hash.
# ----------------------------------------------------------------------
#           07-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # As ApiTools::Presenters::Hash but providing extended DSL facilities for
    # the Platform API documented Types and Resources collection.
    #
    class DocumentedHash < ApiTools::Presenters::Hash
      include ApiTools::Data::DocumentedDSL

      # See ApiTools::Presenters::Hash for details. This subclass method
      # checks for internationalisation in defined key values and propagates
      # the setting up to the hash if present.
      #
      def key(name, options = {}, &block)
        super name, options, &block

        prop = @properties[ name.to_s ]
        if prop && prop.respond_to?( :is_internationalised? ) && prop.is_internationalised?
          internationalised()
        end
      end

      # See ApiTools::Presenters::Hash for details. This subclass method
      # checks for internationalisation in defined key values and propagates
      # the setting up to the hash if present.
      #
      def keys(options = {}, &block)
        super options, &block

        prop = @properties[ 'values' ]

        if prop && prop.respond_to?( :is_internationalised? ) && prop.is_internationalised?
          internationalised()
        end
      end
    end
  end
end
