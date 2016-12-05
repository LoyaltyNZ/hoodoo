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

      # Returns a (newly generated) Hash of search keys mapping to helper Procs
      # which are in the same format as would be passed to
      # Hoodoo::ActiveRecord::Finder::ClassMethods#search_with or
      # Hoodoo::ActiveRecord::Finder::ClassMethods#filter_with, describing the
      # default framework search parameters. The middleware defines keys, but
      # each ORM adapter module must specify how those keys actually get used
      # to search inside supported database engines.
      #
      def self.framework_search_and_filter_data

        # The middleware includes framework-level mappings between URI query
        # string search keys and data validators and processors which convert
        # types where necessary. For example, 'created_at' must be given a
        # valid ISO 8601 subset string and a parsed DateTime will end up in
        # the parsed search hash.
        #
        # Services opt out of framework-level searching at an interface level
        # which means the Finder code herein, under normal flow, will never
        # be asked to process something the interface omits. There is thus no
        # need to try and break encapsulation and come up with a way to read
        # the service interface's omissions. Instead, map everything.
        #
        # This could actually be useful if someone manually drives the #list
        # mechanism with hand-constructed search or filter data that quite
        # intentionally includes framework level parameters even if their own
        # service interface for some reason opts out of allowing them to be
        # exposed to API callers.
        #
        # Note that the #search_with / #filter_with DSL declaration in an
        # appropriately extended model can be used to override the default
        # values wired in below, because the defaults are established by
        # design _before_ the model declarations are processed.
        #
        mapping = {
          'created_after'  => Hoodoo::ActiveRecord::Finder::SearchHelper.cs_gt( :created_at ),
          'created_before' => Hoodoo::ActiveRecord::Finder::SearchHelper.cs_lt( :created_at )
        }

        if mapping.keys.length != ( mapping.keys | Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA.keys ).length
          raise 'Hoodoo::ActiveRecord::Support#framework_search_and_filter_data: Mismatch between internal mapping and Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA'
        end

        return mapping
      end

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
      # * Hoodoo::ActiveRecord::Dated#dated (if "dating_enabled?" is +true+)
      # * Hoodoo::ActiveRecord::ManuallyDated#manually_dated
      #   (if "manual_dating_enabled?" is +true+)
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

        # Due to the mechanism used, dating scope must be done first or the
        # rest of the query may be invalid.
        #
        if klass.include?( Hoodoo::ActiveRecord::Dated ) && klass.dating_enabled?()
          prevailing_scope = prevailing_scope.dated( context )
        end

        if klass.include?( Hoodoo::ActiveRecord::ManuallyDated ) && klass.manual_dating_enabled?()
          prevailing_scope = prevailing_scope.manually_dated( context )
        end

        if klass.include?( Hoodoo::ActiveRecord::Secure )
          prevailing_scope = prevailing_scope.secure( context )
        end

        if klass.include?( Hoodoo::ActiveRecord::Translated )
          prevailing_scope = prevailing_scope.translated( context )
        end

        return prevailing_scope
      end

    end
  end
end
