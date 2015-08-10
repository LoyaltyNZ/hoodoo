########################################################################
# File::    search_helper.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Supplementary helper class included by "finder.rb". See
#           Hoodoo::ActiveRecord::Finder, especially
#           Hoodoo::ActiveRecord::Finder#search_with, for details.
# ----------------------------------------------------------------------
#           09-Jul-2015 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord
    module Finder

      # Help build up Hash maps to pass into Hoodoo::ActiveRecord::Finder
      # methods Hoodoo::ActiveRecord::Finder#search_with and
      # Hoodoo::ActiveRecord::Finder#filter_with.
      #
      # The usage pattern is as follows, using "sh" as a local variable
      # just for brevity - it isn't required:
      #
      #     sh = Hoodoo::ActiveRecord::Finder::SearchHelper
      #
      #     class SomeModel < ActiveRecord::Base
      #       search_with(
      #         :colour       => sh.cs_match,
      #         :name         => sh.ci_match,
      #         :resource_ids => sh.cs_match_csv( :associated_id )
      #       end
      #     end
      #
      # The helper methods just provide values to pass into the Hash used
      # with the search/fitler Hoodoo::ActiveRecord::Finder methods, so
      # they're optional and compatible with calls that write it out "by
      # hand".
      #
      class SearchHelper

        # Case-sensitive match (default-style matching). *WARNING:* This
        # will be case sensitive only if your database is configured for
        # case sensitive matching by default.
        #
        # Results in a <tt>foo = bar</tt> query.
        #
        # +model_field_name+:: If the model attribute name differs from the
        #                      search key you want to use in the URI, give
        #                      the model attribute name here, else omit.
        #
        # Returns a value that can be asssigned to a URI query string key in
        # the Hash given to Hoodoo::ActiveRecord::Finder#search_with or
        # Hoodoo::ActiveRecord::Finder#filter_with.
        #
        def self.cs_match( model_field_name = nil )
          Proc.new { | attr, value |
            [ { model_field_name || attr => value } ]
          }
        end

        # Case-sensitive match of a series of values separated by commas,
        # which are split into an array then processed by AREL back to
        # something SQL-safe.
        #
        # Results in a <tt>foo IN bar,baz,boo</tt> query.
        #
        # +model_field_name+:: If the model attribute name differs from the
        #                      search key you want to use in the URI, give
        #                      the model attribute name here, else omit.
        #
        # Returns a value that can be asssigned to a URI query string key in
        # the Hash given to Hoodoo::ActiveRecord::Finder#search_with or
        # Hoodoo::ActiveRecord::Finder#filter_with.
        #
        def self.cs_match_csv( model_field_name = nil )
          Proc.new { | attr, value |
            [ { model_field_name || attr => value.split( ',' ) } ]
          }
        end

        # Case-sensitive match of a series of values given as an Array.
        # Normally, query string information comes in as a String so the
        # use cases for this are quite unusual; you probably want to use
        # #cs_match_csv most of the time.
        #
        # Results in a <tt>foo IN bar,baz,boo</tt> query.
        #
        # +model_field_name+:: If the model attribute name differs from the
        #                      search key you want to use in the URI, give
        #                      the model attribute name here, else omit.
        #
        # Returns a value that can be asssigned to a URI query string key in
        # the Hash given to Hoodoo::ActiveRecord::Finder#search_with or
        # Hoodoo::ActiveRecord::Finder#filter_with.
        #
        def self.cs_match_array( model_field_name = nil )
          Proc.new { | attr, value |
            [ { model_field_name || attr => [ value ].flatten } ]
          }
        end

        # Case-insensitive match which should be fairly database independent
        # but will run relatively slowly as a result. If you are using
        # PostgreSQL, consider using the faster #ci_match_postgres method
        # instead.
        #
        # Results in a <tt>lower(foo) = bar</tt> query with +bar+ coerced to
        # a String and converted to lower case by Ruby first.
        #
        # +model_field_name+:: If the model attribute name differs from the
        #                      search key you want to use in the URI, give
        #                      the model attribute name here, else omit.
        #
        # Returns a value that can be asssigned to a URI query string key in
        # the Hash given to Hoodoo::ActiveRecord::Finder#search_with or
        # Hoodoo::ActiveRecord::Finder#filter_with.
        #
        def self.ci_match_generic( model_field_name = nil )
          Proc.new { | attr, value |
            [ "lower(#{ model_field_name || attr }) = ?", ( value || '' ).to_s.downcase ]
          }
        end

        # As #ci_match_generic, but adds wildcards at the front and end of
        # the string for a case-insensitive-all-wildcard match.
        #
        def self.ciaw_match_generic( model_field_name = nil )
          Proc.new { | attr, value |
            [ "lower(#{ model_field_name || attr }) LIKE ?", "%#{ ( value || '' ).to_s.downcase }%" ]
          }
        end

        # Case-insensitive match which requires PostgreSQL but should run
        # quickly. If you need a database agnostic solution, consider using
        # the slower #ci_match_generic method instead.
        #
        # Results in a <tt>foo ILIKE bar</tt> query.
        #
        # +model_field_name+:: If the model attribute name differs from the
        #                      search key you want to use in the URI, give
        #                      the model attribute name here, else omit.
        #
        # Returns a value that can be asssigned to a URI query string key in
        # the Hash given to Hoodoo::ActiveRecord::Finder#search_with or
        # Hoodoo::ActiveRecord::Finder#filter_with.
        #
        def self.ci_match_postgres( model_field_name = nil )
          Proc.new { | attr, value |
            [ "#{ model_field_name || attr } ILIKE ?", value ]
          }
        end

        # As #ci_match_postgres, but adds wildcards at the front and end of
        # the string for a case-insensitive-all-wildcard match.
        #
        def self.ciaw_match_postgres( model_field_name = nil )
          Proc.new { | attr, value |
            [ "#{ model_field_name || attr } ILIKE ?", "%#{ value }%" ]
          }
        end
      end

    end
  end
end
