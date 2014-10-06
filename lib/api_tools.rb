root = File.dirname(__FILE__)+'/api_tools/'
require root+'uuid'
require root+'thread_safe'
require root+'logger'
require root+'platform_errors'
require root+'json_errors'
require root+'json_payload'
require root+'platform_context'
require root+'thread_safe'

require root+'services/amqp_message'
require root+'services/request'
require root+'services/response'

require root+'services/http_request'
require root+'services/http_response'

require root+'services/amqp_endpoint'
require root+'services/amqp_multithreaded_endpoint'

require root+'services/base_service'
require root+'services/base_multithreaded_service'
require root+'services/base_client'

require root+'presenters/base_dsl.rb'
require root+'presenters/base_presenter.rb'

require root+'presenters/types/field'
require root+'presenters/types/object'
require root+'presenters/types/array'
require root+'presenters/types/string'
require root+'presenters/types/text'
require root+'presenters/types/enum'
require root+'presenters/types/boolean'
require root+'presenters/types/float'
require root+'presenters/types/integer'
require root+'presenters/types/decimal'
require root+'presenters/types/date'
require root+'presenters/types/date_time'

require root+'data/documented_dsl.rb'
require root+'data/documented_object.rb'
require root+'data/documented_array.rb'
require root+'data/documented_tags.rb'
require root+'data/documented_uuid.rb'
require root+'data/documented_presenter.rb'

# Ordering matters, due to dependencies where one type references another

require root+'data/types/error_primitive.rb'
require root+'data/types/currency.rb'
require root+'data/types/currency_amount.rb'
require root+'data/types/product.rb'
require root+'data/types/basket_item.rb'
require root+'data/types/basket.rb'

require root+'data/resources/errors.rb'
require root+'data/resources/currency.rb'
require root+'data/resources/product.rb'
require root+'data/resources/purchase.rb'
require root+'data/resources/version.rb'

require root+'errors/error_descriptions.rb'
require root+'errors/errors.rb'

require root+'service_middleware/string_inquirer.rb'
require root+'service_middleware/service_middleware.rb'

require root+'service_implementations/service_session.rb'
require root+'service_implementations/service_request.rb'
require root+'service_implementations/service_response.rb'
require root+'service_implementations/service_context.rb'
require root+'service_implementations/service_application.rb'
require root+'service_implementations/service_interface.rb'
require root+'service_implementations/service_implementation.rb'

require root+'utilities.rb'

require root+'version.rb'
