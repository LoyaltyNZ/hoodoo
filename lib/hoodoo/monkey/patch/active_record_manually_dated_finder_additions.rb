########################################################################
# File::    active_record_manually_dated_finder_additions.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Extend Hoodoo::ActiveRecord::Finder::acquire_in_and_update
#           so that it adds error <tt>generic.contemporary_exists</tt>
#           to the provided +context+ if a dated instance is absent.
# ----------------------------------------------------------------------
#           01-Nov-2017 (ADH): Created.
########################################################################

module Hoodoo
  module Monkey
    module Patch

      # Extend Hoodoo::ActiveRecord::Finder::acquire_in_and_update
      # so that it adds error <tt>generic.contemporary_exists</tt>
      # to the provided +context+ if a dated instance is absent.
      #
      module ActiveRecordManuallyDatedFinderAdditions

        # Class methods to patch over an ActiveRecord::Base subclass
        # which includes Hoodoo::ActiveRecord::Finder and
        # Hoodoo::ActiveRecord::Dated.
        #
        module ClassExtensions

          # See Hoodoo::ActiveRecord::Finder::acquire_in_and_update for
          # details. Calls that method then, if +add_errors+ is set to +true+,
          # adds <tt>generic.contemporary_exists</tt> to the given +context+
          # should a contemporary resource instance exist.
          #
          def acquire_in_and_update( context )
            result = super( context )

            if result.nil?
              ident               = context.request.ident
              contemporary_result = scoped_undated_in( context ).
                                    manually_dated_contemporary().
                                    acquire( ident )

              context.response.contemporary_exists( ident ) if contemporary_result.present?
            end

            return result
          end

        end
      end

    end # module Patch
  end   # module Monkey
end     # module Hoodoo
