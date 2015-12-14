########################################################################
# File::    presenters.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the schema based data validation and rendering code.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

module Hoodoo

  # Module providing a namespace for schema-based data rendering and
  # validation code.
  #
  module Presenters
  end
end

# Dependencies

require 'hoodoo/utilities'

# Presenters

require 'hoodoo/presenters/base'
require 'hoodoo/presenters/base_dsl'
require 'hoodoo/presenters/embedding'

require 'hoodoo/presenters/types/field'
require 'hoodoo/presenters/types/object'
require 'hoodoo/presenters/types/array'
require 'hoodoo/presenters/types/hash'
require 'hoodoo/presenters/types/string'
require 'hoodoo/presenters/types/text'
require 'hoodoo/presenters/types/enum'
require 'hoodoo/presenters/types/boolean'
require 'hoodoo/presenters/types/float'
require 'hoodoo/presenters/types/integer'
require 'hoodoo/presenters/types/decimal'
require 'hoodoo/presenters/types/date'
require 'hoodoo/presenters/types/date_time'
require 'hoodoo/presenters/types/tags'
require 'hoodoo/presenters/types/uuid'

require 'hoodoo/presenters/common_resource_fields'
