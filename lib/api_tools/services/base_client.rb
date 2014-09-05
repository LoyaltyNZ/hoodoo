require 'thread'
require 'bunny'
require 'json'

module ApiTools
  module Services
    class BaseClient

      def initialize(amqp_uri)
        @amqp_uri = amqp_uri
        @client_id = ApiTools::UUID.generate
        @response_endpoint = "client.#{@client_id}"
        @requests = ApiTools::ThreadSafeHash.new
      end

      def start
        @connection = Bunny.new(@amqp_uri)
        @connection.start
        @channel = @connection.create_channel
        @exchange = @channel.default_exchange

        wait_connection_queue = Queue.new

        # Gets Responses from services
        @listener_thread = Thread.new do

          connection = Bunny.new(@amqp_uri)
          connection.start
          channel = connection.create_channel
          response_queue = channel.queue(@response_endpoint, :exclusive => true, :auto_delete => true)

          wait_connection_queue << true

          loop do
            response_queue.subscribe(:block=>true) do |delivery_info, metadata, payload|
              if @requests.has_key?(metadata[:correlation_id])
                @requests[metadata[:correlation_id]][:queue] << { :type => metadata[:type], :data => JSON.parse(payload, :symbolize_names => true) }
              end
            end
          end

          connection.close
        end

        @listener_thread.run

        wait_connection_queue.pop
      end

      def request(to, data)
        message_id = ApiTools::UUID.generate
        @exchange.publish(JSON.fast_generate(data), {
          :message_id => message_id,
          :routing_key => to,
          :reply_to => @response_endpoint,
          :content_type => 'application/json; charset=utf-8',
        })

        queue = Queue.new
        @requests[message_id] = { :queue => queue }

        response = queue.pop
        @requests.delete(message_id)
        response
      end
    end
  end
end