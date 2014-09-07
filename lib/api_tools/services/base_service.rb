require 'thread'
require 'bunny'
require 'json'

module ApiTools
  module Services
    class BaseService

      attr_accessor :amqp_uri, :service_instance_id, :listener_endpoint, :response_endpoint, :response_thread, :timeout

      def initialize(amqp_uri, name, options = {})
        @amqp_uri = amqp_uri
        @service_instance_id = ApiTools::UUID.generate
        @listener_endpoint = "service.#{name}"
        @response_endpoint = "service.#{name}.#{@service_instance_id}"
        @requests = ApiTools::ThreadSafeHash.new
        @timeout ||= options[:timeout]
        @timeout ||= 5000
      end

      def instance_id
        @service_instance_id
      end

      def process(data, metadata, channel)
        raise "Abstract!"
      end

      def start
        wait_connection_queue = Queue.new

        # This thread listens for requests
        @request_thread = Thread.new do
          connection = Bunny.new(@amqp_uri)
          connection.start
          channel = connection.create_channel
          channel.prefetch(1)
          listener_queue = channel.queue(@listener_endpoint)

          loop do
            listener_queue.subscribe(:ack => true, :block => true, :timeout => 1) do |delivery_info, metadata, payload|
              payload = JSON.parse(payload, :symbolize_names => true)
              begin
                data = process(payload, metadata, channel)
                respond(channel.default_exchange, metadata[:reply_to], metadata[:message_id], 'response', data)
                channel.ack(delivery_info.delivery_tag)
              rescue Exception => e
                respond(channel.default_exchange, metadata[:reply_to], metadata[:message_id], 'error', { :code => 500, :message => e.message})
                channel.nack(delivery_info.delivery_tag, :requeue => false)
              end

            end
          end

          connection.close
        end

        # This thread enqeues responses
        @response_thread = Thread.new do
          connection = Bunny.new(@amqp_uri)
          connection.start
          channel = connection.create_channel
          queue = channel.queue(@response_endpoint, :exclusive => true, :auto_delete => true)

          wait_connection_queue << true

          loop do
            queue.subscribe(:block => true)  do |delivery_info, metadata, payload|
              if @requests.has_key?(metadata[:correlation_id])
                @requests[metadata[:correlation_id]][:queue] << { :type => metadata[:type], :data => JSON.parse(payload, :symbolize_names => true) }
              end
            end
          end

          connection.close
        end

        @response_thread.run
        wait_connection_queue.pop
        @request_thread.run
      end

      def join
        @request_thread.join
      end

      def request(exchange, to, data)
        message_id = ApiTools::UUID.generate

        exchange.publish(JSON.fast_generate(data), {
          :message_id => message_id,
          :routing_key => to,
          :reply_to => @response_endpoint
        })

        queue = Queue.new
        @requests[message_id] = { :queue => queue }
        begin
          Timeout::timeout(@timeout / 1000.0) do
            response = queue.pop
            @requests.delete(message_id)
            return response
          end
        rescue TimeoutError
          return
        end
      end

      def respond(exchange, to, correlation_id, type, data = {})
        exchange.publish(JSON.fast_generate(data), {
          :message_id => ApiTools::UUID.generate,
          :routing_key => to,
          :type => type,
          :correlation_id => correlation_id,
          :content_type => 'application/json; charset=utf-8',
        })
      end

      def stop
        @response_thread.terminate
      end
    end
  end
end