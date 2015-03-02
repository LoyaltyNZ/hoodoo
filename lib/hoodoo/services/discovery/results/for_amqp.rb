module Hoodoo
  module Services
    module Discovery
      class ForAMQP

        attr_accessor :resource
        attr_accessor :version
        attr_accessor :queue_name
        attr_accessor :equivalent_path

        def initialize( resource:,
                        version:,
                        queue_name:,
                        equivalent_path: )

          self.resource        = resource.to_s
          self.version         = version
          self.queue_name      = queue_name
          self.equivalent_path = equivalent_path
        end
      end
    end
  end
end
