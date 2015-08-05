########################################################################
# File::    support.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: This file includes a support class that is basically a
#           public, independent expression of a series of specialised
#           methods that would otherwise have been private, were it not
#           for them being called by mixin code. See
#           Hoodoo::ActiveRecord::Support documentation for details.
# ----------------------------------------------------------------------
#           14-Jul-2015 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Most of the ActiveRecord support code provides mixins with
    # a public API. That public interface makes it obvious what
    # the mixin's defined method names will be, helping to avoid
    # collisions/shadowing. Sometimes, those methods want to share
    # code but private methods don't work well in that context -
    # their names could unwittingly collide with names in the
    # including class, written by an author not aware of those
    # essentially hidden but vital interfaces.
    #
    # This is a support class specifically designed to solve this
    # issue. It's really a public, independent expression of a
    # series of specialised methods that would otherwise have
    # normally been private.
    #
    # Although this code forms part of the Hoodoo public API, its
    # unusual status means that you should not really call any of
    # these methods unless you're prepared to track unexpected
    # API changes in them in future and update your calling code.
    #
    class Support

      # Takes a Hash of possibly-non-String keys and with +nil+ values or
      # Proc instances appropriate for Hoodoo::ActiveRecord::Finder#search_with
      # / #filter_with. Returns a similar Hash with all-String keys and a Proc
      # for every value.
      #
      # +hash+:: Hash Symbol or String keys and Proc instance or +nil+
      #          values.
      #
      def self.process_to_map( hash )
        map = Hoodoo::Utilities.stringify( hash )

        map.each do | attr, proc_or_nil |
          if proc_or_nil.nil?
            map[ attr ] = Hoodoo::ActiveRecord::Finder::SearchHelper.cs_match( attr )
          end
        end

        return map
      end

      # Given an ActiveRecord class and Hoodoo request context, work out which
      # Hoodoo support modules are included within this class and call base
      # methods to provide a fully specified basic query chain obeying all the
      # necessary aspects of the ActiveRecord model class and the request.
      #
      # Each of the following are called if the owning module is included:
      #
      # * Hoodoo::ActiveRecord::Secure#secure
      # * Hoodoo::ActiveRecord::Translated#translated
      # * Hoodoo::ActiveRecord::Dated#dated
      #
      # +klass+::   The ActiveRecord::Base subclass _class_ (not instance)
      #             which is making the call here. This is the entity which is
      #             checked for module inclusions to determine how the query
      #             chain should be assembled.
      #
      # +context+:: Hoodoo::Services::Context instance describing a call
      #             context. This is typically a value passed to one of
      #             the Hoodoo::Services::Implementation instance methods
      #             that a resource subclass implements.
      #
      # Returns an ActiveRecord::Relation instance which is anything from a
      # generic anonymous scope, all the way through to a secured, translated,
      # backdated scope for use with subsequent query refinements.
      #
      def self.full_scope_for( klass, context )
        prevailing_scope = klass.all() # "Model.all" -> returns anonymous scope
        modules          = klass.included_modules()

        # Due to the mechanism used, dating scope must be done first or the
        # rest of the query may be invalid.
        #
        if modules.include?( Hoodoo::ActiveRecord::Dated )
          prevailing_scope = prevailing_scope.dated( context )
        end

        if modules.include?( Hoodoo::ActiveRecord::Secure )
          prevailing_scope = prevailing_scope.secure( context )
        end

        if modules.include?( Hoodoo::ActiveRecord::Translated )
          prevailing_scope = prevailing_scope.translated( context )
        end

        return prevailing_scope
      end

    end
  end
end
