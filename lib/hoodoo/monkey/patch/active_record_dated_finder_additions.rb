########################################################################
# File::    active_record_dated_finder_additions.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Extend
#           Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in! so
#           that it adds error +generic.contemporary_exists+ to the
#           provided +context+ if a dated instance is absent.
# ----------------------------------------------------------------------
#           01-Nov-2017 (ADH): Created.
########################################################################

module Hoodoo
  module Monkey
    module Patch

      # Extend Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in! so
      # that it adds error +generic.contemporary_exists+ to the provided
      # +context+ if a dated instance is absent.
      #
      module ActiveRecordDatedFinderAdditions

        # Class methods to patch over an ActiveRecord::Base subclass
        # which includes Hoodoo::ActiveRecord::Finder and
        # Hoodoo::ActiveRecord::Dated.
        #
        module ClassExtensions

          # See Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in! for
          # details. Calls that method then, upon error, checks to see if a
          # contemporary version of the resource exists and adds error
          # +generic.contemporary_exists+ to the given +context+ if so.
          #
          def acquire_in!( context )
            result = super( context )

            if result.nil? && context.request.dated_at
              ident               = context.request.ident
              contemporary_result = scoped_undated_in( context ).acquire( ident )

              context.response.contemporary_exists( ident ) if contemporary_result.present?
            end

            return result
          end

        end
      end

    end # module Patch
  end   # module Monkey
end     # module Hoodoo
