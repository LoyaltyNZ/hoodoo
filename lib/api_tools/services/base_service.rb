require 'thread'
require 'bunny'

module ApiTools
  module Services
    class BaseService < AQMPEndpoint

      attr_accessor :service_endpoint, :service_thread

      def initialize(amqp_uri, name, options = {})
        super amqp_uri, options
        @service_endpoint = "service.#{name}"
        @response_endpoint = "service.#{name}.#{@endpoint_id}"
      end

      def process(request)
        raise "#process is abstract. Please override it in your implementation."
      end

      def create_service_thread
        begin
          Thread.new do
            connection = Bunny.new(@amqp_uri)
            connection.start
            channel = connection.create_channel
            channel.prefetch(1)
            listener_queue = channel.queue(@service_endpoint)

            @boot_queue << true

            loop do
              listener_queue.subscribe(:ack => true, :block => true) do |delivery_info, metadata, payload|
                begin
                  request = request_class.new(channel.default_exchange, {
                    :message_id => metadata.message_id,
                    :type => metadata.type,
                    :correlation_id => metadata.correlation_id,
                    :reply_to => metadata.reply_to,
                    :content_type => metadata.content_type,
                    :received_by => delivery_info.routing_key,
                    :response_class => response_class,
                    :payload => payload,
                  })
                  response = process(request)
                  response.send_message if !response.nil? && response.class <= ApiTools::Services::Response
                  channel.ack(delivery_info.delivery_tag)
                rescue Exception => e
                  ApiTools::Logger.error(e.message)
                  # response = ApiTools::Services::Response.new(channel.default_exchange,{
                  #   :routing_key => request.reply_to,
                  #   :type => 'error',
                  #   :payload => '{"error":"'+e.message+'"}',
                  #   :content_type => 'application/json',
                  # })
                  # response.send_message
                  channel.nack(delivery_info.delivery_tag, :requeue => false)
                end
              end
            end
          end
        rescue Exception => e
          @boot_queue << false
        end
      end

      def start
        super

        # This thread listens for requests
        @service_thread = create_service_thread
        @service_thread.run
        raise RuntimeError.new("Request Thread did not initialize") unless @boot_queue.pop
      end

      def join
        @service_thread.join
      end

      def stop
        @service_thread.terminate
        super
      end
    end
  end
end