########################################################################
# File::    data.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include common Type and Resource definitions.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

module Hoodoo

  # This module provides a namespace for definitions of data types and
  # formal resources which an API uses and implements through its various
  # supporting services.
  #
  module Data

    # Module used as a namespace to collect classes that represent
    # Resources documented by the your platform's API. Each is an
    # Hoodoo::Presenters::Base subclass, so can be used to render
    # and validate JSON data.
    #
    module Resources
    end

    # Module used as a namespace to collect classes that represent
    # Types documented by your platform's API. Each is an
    # Hoodoo::Presenters::Base subclass, so can be used to render
    # and validate JSON data.
    #
    module Types
    end
  end
end

# Dependencies

require 'hoodoo/presenters'

# Ordering matters, due to dependencies where one type references another

require 'hoodoo/data/types/error_primitive'
require 'hoodoo/data/types/permissions'
require 'hoodoo/data/types/permissions_defaults'
require 'hoodoo/data/types/permissions_resources'
require 'hoodoo/data/types/permissions_full'

require 'hoodoo/data/resources/caller'
require 'hoodoo/data/resources/errors'
require 'hoodoo/data/resources/log'
require 'hoodoo/data/resources/session'
