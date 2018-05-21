########################################################################
# File::    security_helper.rb
# (C)::     Loyalty New Zealand 2018
#
# Purpose:: Supplementary helper class included by "finder.rb". See
#           Hoodoo::ActiveRecord::Secure, especially
#           Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with and
#           its options Hash, for details.
# ----------------------------------------------------------------------
#           05-Apr-2018 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord
    module Secure

      # Help build security exemption Procs to pass into
      # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with via its options
      # Hash. The following extends an example given in the documentation (at
      # the time of writing here) for the underlying implementation method
      # Hoodoo::ActiveRecord::Secure::ClassMethods#secure:
      #
      #     class Audit < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Secure
      #
      #       secure_with(
      #         {
      #           :creating_caller_uuid => :authorised_caller_uuids
      #         },
      #         {
      #           :exemptions => Hoodoo::ActiveRecord::Secure::SecurityHelper::includes_wildcard( '*' )
      #         }
      #       )
      #     end
      #
      # Note that the Hoodoo::ActiveRecord::Secure module includes some belper
      # constants to aid brevity for common cases such as the single value
      # <tt>#eql?</tt> or enumerable <tt>#include?</tt> matchers checking for
      # a '*' as an indiscriminate wildcard - see for example
      # Hoodoo::ActiveRecord::Secure::ENUMERABLE_INCLUDES_STAR.
      #
      class SecurityHelper

        # Internally used by ::matches_wildcard for Ruby 2.4.0+ performance.
        #
        RUBY_FAST_WILDCARD_PROC_CONTENTS = %q{
          security_value.match?( wildcard_regexp ) rescue false
        }

        # Internally used by ::matches_wildcard for Ruby < 2.4 compatibility.
        #
        RUBY_SLOW_WILDCARD_PROC_CONTENTS = %q{
          wildcard_regexp.match( security_value ) != nil rescue false
        }

        # Match a given wildcard, typically a String, to a single value
        # via <tt>#eql?</tt>.
        #
        # +wildcard_value+:: Wildcard value to match, e.g. <tt>'*'</tt>.
        #
        # Returns a Proc suitable for passing to the +:exemptions+ option for
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with.
        #
        def self.eqls_wildcard( wildcard_value )
          Proc.new do | security_value |
            security_value.eql?( wildcard_value ) rescue false
          end
        end

        # Match a given wildcard, typically a String, inside an Enumerable
        # subclass via <tt>#include?</tt>.
        #
        # +wildcard_value+:: Wildcard value to match, e.g. <tt>'*'</tt>.
        #
        # Returns a Proc suitable for passing to the +:exemptions+ option for
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with.
        #
        def self.includes_wildcard( wildcard_value )
          Proc.new do | security_values |
            security_values.is_a?( Enumerable ) &&
            security_values.include?( wildcard_value ) rescue false
          end
        end

        # Match a given wildcard Regexp to a value via <tt>#match?</tt>.
        #
        # +wildcard_value+:: Wildcard Regexp to use, e.g. <tt>/.*/</tt>.
        #                    Strings are coerced to Regexps without any
        #                    escaping but doing so reduces performance.
        #
        # Returns a Proc suitable for passing to the +:exemptions+ option for
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with.
        #
        def self.matches_wildcard( wildcard_regexp )
          wildcard_regexp = Regexp.new( wildcard_regexp ) unless wildcard_regexp.is_a?( Regexp )

          # Use security_value's #match? (if present) to ensure that we have
          # an expected "matchable" type. This is only available in Ruby 2.4
          # or later, so a patch is performed below for earlier Rubies.
          #
          Proc.new do | security_value |

            # Ruby 2.4.0 and later introduce the Regexp#match? family, which
            # is the fastest way to determine a simple does-or-does-not match
            # condition. Ruby 2.3.x and earlier need different, slower code.
            #
            if ''.respond_to?( :match? )
              eval( RUBY_FAST_WILDCARD_PROC_CONTENTS )
            else
              eval( RUBY_SLOW_WILDCARD_PROC_CONTENTS )
            end
          end
        end

        # Match a given wildcard Regexp to any value in an enumerable
        # object via iteration and <tt>#match?</tt>. Exists with +true+
        # as soon as any match is made.
        #
        # +wildcard_value+:: Wildcard Regexp to use, e.g. <tt>/.*/</tt>.
        #                    Strings are coerced to Regexps without any
        #                    escaping but doing so reduces performance.
        #
        # Returns a Proc suitable for passing to the +:exemptions+ option for
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with.
        #
        def self.matches_wildcard_enumerable( wildcard_regexp )
          match_proc = self.matches_wildcard( wildcard_regexp )

          Proc.new do | security_values |
            begin
              security_values.any? do | security_value |
                match_proc.call( security_value )
              end
            rescue
              false
            end
          end
        end

      end
    end
  end
end
