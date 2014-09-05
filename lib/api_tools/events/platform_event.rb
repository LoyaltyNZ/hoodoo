module ApiTools
  module Events
    class PlatformEvent
      def self.publish_event(topic, data)
        # TODO: Query DNS to get NSQ nodes.
        # TODO: Write Event to NSQ.
      end
    end
  end
end