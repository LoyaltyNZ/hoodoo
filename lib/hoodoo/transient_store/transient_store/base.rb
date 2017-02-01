########################################################################
# File::    base.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Base class for Base class for Hoodoo::TransientStore plugins.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

module Hoodoo
  class TransientStore

    # Base class for Hoodoo::TransientStore plugins. This is in effect just a
    # template / abstract class, providing a source-level guideline for plug-in
    # authors. See also out-of-the-box existing plug-ins as worked examples.
    #
    class Base

      # Base class template for a constructor. *DO* *NOT* call +super()+ in
      # subclass constructors!
      #
      # +storage_host_uri+:: The engine-dependent connection URI. See
      #                      Hoodoo::TransientStore::new for details.
      #
      def initialize( storage_host_uri: )
        raise "Subclasses must implement a constructor compatible with Hoodoo::TransientStore::Base\#initialize"
      end

      # Base class template for the plug-in's back-end implementation of
      # Hoodoo::TransientStore#set - see that for details.
      #
      # The implementation is free to raise an exception if an error is
      # encountered while trying to set the data - this will be caught and
      # returned by Hoodoo::TransientStore#set. Otherwise return +true+ on
      # success or +false+ for failures of unknown origin.
      #
      def set( key:, payload:, maximum_lifespan: nil )
        raise "Subclasses must implement Hoodoo::TransientStore::Base\#set"
      end

      # Base class template for the plug-in's back-end implementation of
      # Hoodoo::TransientStore#get - see that for details.
      #
      # The implementation is free to raise an exception if an error is
      # encountered while trying to get the data - this will be caught and
      # +nil+ returned by Hoodoo::TransientStore#get.
      #
      def get( key: )
        raise "Subclasses must implement Hoodoo::TransientStore::Base\#get"
      end

      # Base class template for the plug-in's back-end implementation of
      # Hoodoo::TransientStore#delete - see that for details.
      #
      # The implementation is free to raise an exception if an error is
      # encountered while trying to get the data - this will be caught and
      # ignored by Hoodoo::TransientStore#delete.
      #
      def delete( key: )
        raise "Subclasses must implement Hoodoo::TransientStore::Base\#delete"
      end
    end
  end
end
