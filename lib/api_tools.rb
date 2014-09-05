root = File.dirname(__FILE__)+'/api_tools/'
require root+'uuid'
require root+'thread_safe'
require root+'logger'
require root+'platform_errors'
require root+'json_errors'
require root+'json_payload'
require root+'platform_context'

require root+'services/base_service'
require root+'services/base_client'

require root+'presenters/types/field'
require root+'presenters/types/object'
require root+'presenters/types/array'
require root+'presenters/types/string'
require root+'presenters/types/boolean'
require root+'presenters/types/float'
require root+'presenters/types/integer'
require root+'presenters/types/decimal'
require root+'presenters/types/date'
require root+'presenters/types/date_time'

require root+'presenters/base_presenter.rb'

require root+'version.rb'
