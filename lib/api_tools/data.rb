########################################################################
# File::    data.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include common Type and Resource definitions.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'presenters'

# Ordering matters, due to dependencies where one type references another

require 'data/types/constraints'
require 'data/types/error_primitive'
require 'data/types/currency'
require 'data/types/currency_amount'
require 'data/types/product'
require 'data/types/basket_item'
require 'data/types/basket'
require 'data/types/calculator_common'
require 'data/types/voucher_earner'
require 'data/types/currency_earner'
require 'data/types/calculator_configuration'

require 'data/resources/account'
require 'data/resources/member'
require 'data/resources/token'
require 'data/resources/balance'
require 'data/resources/calculation'
require 'data/resources/calculator'
require 'data/resources/currency'
require 'data/resources/errors'
require 'data/resources/involvement'
require 'data/resources/ledger'
require 'data/resources/log'
require 'data/resources/outlet'
require 'data/resources/participant'
require 'data/resources/product'
require 'data/resources/programme'
require 'data/resources/membership'
require 'data/resources/purchase'
require 'data/resources/transaction'
require 'data/resources/version'
require 'data/resources/voucher'
