root = File.dirname(__FILE__)+'/api_tools/'

require root+'utilities'
require root+'logger'
require root+'uuid'

# Schema based data validation and rendering

require root+'presenters/base'
require root+'presenters/base_dsl'

require root+'presenters/types/field'
require root+'presenters/types/object'
require root+'presenters/types/array'
require root+'presenters/types/hash'
require root+'presenters/types/string'
require root+'presenters/types/text'
require root+'presenters/types/enum'
require root+'presenters/types/boolean'
require root+'presenters/types/float'
require root+'presenters/types/integer'
require root+'presenters/types/decimal'
require root+'presenters/types/date'
require root+'presenters/types/date_time'
require root+'presenters/types/tags'
require root+'presenters/types/uuid'

require root+'presenters/common_resource_fields'

# Ordering matters, due to dependencies where one type references another

require root+'data/types/constraints'
require root+'data/types/error_primitive'
require root+'data/types/currency'
require root+'data/types/currency_amount'
require root+'data/types/product'
require root+'data/types/basket_item'
require root+'data/types/basket'
require root+'data/types/calculator_common'
require root+'data/types/voucher_earner'
require root+'data/types/currency_earner'
require root+'data/types/calculator_configuration'

require root+'data/resources/account'
require root+'data/resources/member'
require root+'data/resources/token'
require root+'data/resources/balance'
require root+'data/resources/calculation'
require root+'data/resources/calculator'
require root+'data/resources/currency'
require root+'data/resources/errors'
require root+'data/resources/involvement'
require root+'data/resources/log'
require root+'data/resources/outlet'
require root+'data/resources/participant'
require root+'data/resources/product'
require root+'data/resources/programme'
require root+'data/resources/membership'
require root+'data/resources/purchase'
require root+'data/resources/transaction'
require root+'data/resources/version'
require root+'data/resources/voucher'

require root+'errors/error_descriptions'
require root+'errors/errors'

# Ordering matters, due to dependencies in module/class hierarchy namespace

require root+'service_middleware/string_inquirer'
require root+'service_middleware/rack_monkey_patch'
require root+'service_middleware/service_registry_drb_server'
require root+'service_middleware/amqp_log_message'
require root+'service_middleware/structured_logger'
require root+'service_middleware/service_middleware'
require root+'service_middleware/service_endpoint'

require root+'service_middleware/exception_reporting/exception_reporting'
require root+'service_middleware/exception_reporting/reporters/base'
require root+'service_middleware/exception_reporting/reporters/airbrake_reporter'
require root+'service_middleware/exception_reporting/reporters/raygun_reporter'

require root+'service_implementations/service_session'
require root+'service_implementations/service_request'
require root+'service_implementations/service_response'
require root+'service_implementations/service_context'
require root+'service_implementations/service_application'
require root+'service_implementations/service_interface'
require root+'service_implementations/service_implementation'

# Optional ActiveRecord (and related ActiveModel) related components

require root+'active_model/uuid_validator'

require root+'active_record/error_mapping'
require root+'active_record/finder'
require root+'active_record/uuid'
require root+'active_record/base'

require root+'version'
