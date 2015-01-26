########################################################################
# File::    presenters.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the schema based data validation and rendering code.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

require 'presenters/base'
require 'presenters/base_dsl'

require 'presenters/types/field'
require 'presenters/types/object'
require 'presenters/types/array'
require 'presenters/types/hash'
require 'presenters/types/string'
require 'presenters/types/text'
require 'presenters/types/enum'
require 'presenters/types/boolean'
require 'presenters/types/float'
require 'presenters/types/integer'
require 'presenters/types/decimal'
require 'presenters/types/date'
require 'presenters/types/date_time'
require 'presenters/types/tags'
require 'presenters/types/uuid'

require 'presenters/common_resource_fields'
