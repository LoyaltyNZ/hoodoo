########################################################################
# File::    data.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include common Type and Resource definitions.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

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

require 'hoodoo/data/resources/account'
require 'hoodoo/data/resources/member'
require 'hoodoo/data/resources/token'
require 'hoodoo/data/resources/balance'
require 'hoodoo/data/resources/calculation'
require 'hoodoo/data/resources/calculator'
require 'hoodoo/data/resources/currency'
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
require 'hoodoo/data/resources/transaction'
require 'hoodoo/data/resources/version'
require 'hoodoo/data/resources/voucher'
