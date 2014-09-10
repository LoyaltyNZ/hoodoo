require 'thread'
require 'bunny'
require 'json'

module ApiTools
  module Services
    class BaseService

      attr_accessor :amqp_uri, :service_instance_id, :listener_endpoint, :response_endpoint, :timeout

      attr_accessor :requests, :request_thread, :response_thread

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

      def process(request)
        raise "#process is abstract. Please override it in your implementation."
      end

      def create_request_thread(wait_queue)
        begin
          Thread.new do
            connection = Bunny.new(@amqp_uri)
            connection.start
            channel = connection.create_channel
            channel.prefetch(1)
            listener_queue = channel.queue(@listener_endpoint)

            wait_queue << true

            loop do
              listener_queue.subscribe(:ack => true, :block => true, :timeout => 1) do |delivery_info, metadata, payload|
                begin
                  request = ApiTools::Services::Request.new(channel.default_exchange, {
                    :delivery_info => delivery_info,
                    :metadata => metadata,
                    :payload => payload,
                  })
                  response = process(request)
                  response.send_message if response <= ApiTools::Services::Response
                  channel.ack(delivery_info.delivery_tag)
                rescue Exception => e
                  response = request.create_response({
                    :type => 'error',
                    :payload => { :code => 500, :message => e.message}
                  })
                  respond(response)
                  channel.nack(delivery_info.delivery_tag, :requeue => false)
                end
              end
            end
          end
        rescue Exception => e
          wait_queue << false
        end
      end

      def create_response_thread(wait_queue)
        begin
          Thread.new do
            connection = Bunny.new(@amqp_uri)
            connection.start
            channel = connection.create_channel
            queue = channel.queue(@response_endpoint, :exclusive => true, :auto_delete => true)

            wait_queue << true

            loop do
              queue.subscribe(:block => true)  do |delivery_info, metadata, payload|
                if @requests.has_key?(metadata[:correlation_id])
                  @requests[metadata[:correlation_id]][:queue] << { :type => metadata[:type], :data => JSON.parse(payload, :symbolize_names => true) }
                end
              end
            end
          end
        rescue Exception => e
          wait_queue << false
        end
      end

      def start
        wait_queue = Queue.new

        # This thread listens for requests
        @request_thread = create_request_thread(wait_queue)

        # This thread enqeues responses
        @response_thread = create_response_thread(wait_queue)

        @response_thread.run
        raise RuntimeError.new("Response Thread did not initialize") unless wait_queue.pop
        @request_thread.run
        raise RuntimeError.new("Request Thread did not initialize") unless wait_queue.pop
      end

      def join
        @request_thread.join
      end

      def send_async_request(request)
        request.send_message
        @requests[message_id] = request
      end

      def send_sync_request(request)
        send_async_request(request)
        begin
          Timeout::timeout(@timeout / 1000.0) do
            response = request.queue.pop
            @requests.delete(message_id)
            return response
          end
        rescue TimeoutError
          @requests.delete(message_id)
          return nil
        end
      end

      def stop
        @request_thread.terminate
        @response_thread.terminate
      end
    end
  end
end