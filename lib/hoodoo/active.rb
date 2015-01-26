########################################################################
# File::    active.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include ActiveRecord-/ActiveModel-dependent optional
#           extras.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'hoodoo/utilities'
require 'hoodoo/errors'

# ActiveRecord / ActiveModel extras

require 'hoodoo/active/active_model/uuid_validator'

require 'hoodoo/active/active_record/error_mapping'
require 'hoodoo/active/active_record/finder'
require 'hoodoo/active/active_record/uuid'
require 'hoodoo/active/active_record/base'