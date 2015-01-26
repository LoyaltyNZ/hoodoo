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

require 'utilities'
require 'errors'

# ActiveRecord / ActiveModel extras

require 'active/active_model/uuid_validator'

require 'active/active_record/error_mapping'
require 'active/active_record/finder'
require 'active/active_record/uuid'
require 'active/active_record/base'
