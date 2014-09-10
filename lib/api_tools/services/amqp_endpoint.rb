require 'thread'
require 'bunny'

module ApiTools
  module Services
    class AQMPEndpoint

      attr_accessor :exchange, :amqp_uri, :endpoint_id, :response_endpoint, :timeout, :requests, :response_thread

      def initialize(amqp_uri, options = {})
        @amqp_uri = amqp_uri
        @endpoint_id = ApiTools::UUID.generate
        @response_endpoint = "endpoint.#{@endpoint_id}"
        @requests = ApiTools::ThreadSafeHash.new
        @timeout ||= options[:timeout]
        @timeout ||= 5000
        @boot_queue = Queue.new
      end

      def create_response_thread
        begin
          Thread.new do
            connection = Bunny.new(@amqp_uri)
            connection.start
            channel = connection.create_channel
            queue = channel.queue(@response_endpoint, :exclusive => true, :auto_delete => true)

            @exchange = channel.default_exchange

            @boot_queue << true

            loop do
              queue.subscribe(:block => true) do |delivery_info, metadata, payload|
                if @requests.has_key?(metadata[:correlation_id])
                  response = Response.new(@exchange, {
                    :message_id => metadata.message_id,
                    :type => metadata.type,
                    :correlation_id => metadata.correlation_id,
                    :reply_to => metadata.reply_to,
                    :content_type => metadata.content_type,
                    :received_by => delivery_info.routing_key,
                    :payload => payload,
                  })
                  @requests[metadata[:correlation_id]].queue << response
                end
              end
            end
          end
        rescue Exception => e
          @boot_queue << false
        end
      end

      def start
        @boot_queue.clear

        # This thread enqeues responses
        @response_thread = create_response_thread

        @response_thread.run
        raise RuntimeError.new("Response Thread did not initialize") unless @boot_queue.pop
      end

      def join
        @response_thread.join
      end

      def request(to, payload)
        req = ApiTools::Services::Request.new(@exchange, {
          :routing_key => to,
          :type => 'request',
          :payload => payload,
        })
        [ req, send_sync_request(req) ]
      end

      def send_async_request(request)
        request.reply_to = @response_endpoint
        request.send_message
        @requests[request.message_id] = request
        request
      end

      def send_sync_request(request)
        send_async_request(request)
        response = nil
        begin
          Timeout::timeout(@timeout / 1000.0) do
            response = request.queue.pop
          end
        rescue TimeoutError
          request.timed_out = true
          @requests.delete(request.message_id)
        end
        @requests.delete(request.message_id)
        response
      end

      def stop
        @response_thread.terminate
      end
    end
  end
end