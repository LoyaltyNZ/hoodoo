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
    # Hoodoo::Data::Resources::Version is defined as an example
    # class. The Hoodoo::Data::Resources::* namespace is otherwise
    # free for use by Hoodoo clients (indeed, types or resources
    # that wish to reference one another through the DSL *must*
    # use this namespace).
    #
    module Resources
    end

    # Module used as a namespace to collect classes that represent Types
    # documented by your platform's API. Each is an
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

require 'hoodoo/data/types/constraints'
require 'hoodoo/data/types/error_primitive'
require 'hoodoo/data/types/currency'
require 'hoodoo/data/types/currency_amount'
require 'hoodoo/data/types/product'
require 'hoodoo/data/types/basket_item'
require 'hoodoo/data/types/basket'
require 'hoodoo/data/types/calculator_common'
require 'hoodoo/data/types/voucher_earner'
require 'hoodoo/data/types/currency_earner'
require 'hoodoo/data/types/calculator_configuration'
require 'hoodoo/data/types/permissions'
require 'hoodoo/data/types/permissions_defaults'
require 'hoodoo/data/types/permissions_resources'
require 'hoodoo/data/types/permissions_full'
require 'hoodoo/data/types/financial_manipulation'

require 'hoodoo/data/resources/account'
require 'hoodoo/data/resources/member'
require 'hoodoo/data/resources/token'
require 'hoodoo/data/resources/balance'
require 'hoodoo/data/resources/calculation'
require 'hoodoo/data/resources/calculator'
require 'hoodoo/data/resources/caller'
require 'hoodoo/data/resources/credit'
require 'hoodoo/data/resources/currency'
require 'hoodoo/data/resources/debit'
require 'hoodoo/data/resources/errors'
require 'hoodoo/data/resources/involvement'
require 'hoodoo/data/resources/ledger'
require 'hoodoo/data/resources/log'
require 'hoodoo/data/resources/outlet'
require 'hoodoo/data/resources/participant'
require 'hoodoo/data/resources/product'
require 'hoodoo/data/resources/programme'
require 'hoodoo/data/resources/membership'
require 'hoodoo/data/resources/purchase'
require 'hoodoo/data/resources/refund'
require 'hoodoo/data/resources/session'
require 'hoodoo/data/resources/tag'
require 'hoodoo/data/resources/version'
require 'hoodoo/data/resources/voucher'
