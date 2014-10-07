require 'thread'
require 'bunny'

module ApiTools
  module Services
    class AQMPMultithreadedEndpoint

      attr_accessor :exchange, :amqp_uri, :endpoint_id, :request_endpoint, :response_endpoint, :timeout, :response_thread
      attr_accessor :request_class, :queue_options, :thread_count
      attr_reader :rx_queue, :tx_queue, :rx_thread, :tx_thread, :worker_threads, :connection, :rx_channel, :tx_channel

      def initialize(amqp_uri, options = {})
        @amqp_uri = amqp_uri
        @endpoint_id = options[:endpoint_id] || ApiTools::UUID.generate
        @request_endpoint = options[:request_endpoint] || "endpoint.#{@endpoint_id}"
        @response_endpoint = options[:response_endpoint] || "endpoint.#{@endpoint_id}.response"

        @timeout = options[:timeout] || 5000
        @queue_options =options[:queue_options] || {:exclusive => true, :auto_delete => true}
        @request_class = options[:request_class] || ApiTools::Services::Request
        @thread_count = options[:thread_count] || (self.class.number_of_processors/2).floor
        @prefetch = options[:prefetch] || 1

        @worker_threads = []
        @boot_queue = Queue.new
        @rx_queue = Queue.new
        @tx_queue = Queue.new

      end

      def connect
        @connection = Bunny.new(@amqp_uri)
        @connection.start
      end

      def close
        @connection.close
      end

      def process(message)
        raise "#process is abstract. Please override it in your implementation."
      end

      def create_worker_thread
        Thread.new do
          loop do
            begin
              message = @rx_queue.pop
              response = process(message)
              @tx_queue << response if !response.nil? && response.class <= ApiTools::Services::Response
            rescue Interrupt
              break
            rescue Exception => e
              ApiTools::Logger.error e
            end
          end
        end
      end

      def create_rx_thread
        @rx_thread = Thread.new do
          @rx_channel = @connection.create_channel
          queue = @rx_channel.queue(@request_endpoint, @queue_options)

          @boot_queue << true
          @rx_channel.prefetch(@prefetch)
          loop do
            begin
              queue.subscribe(:ack => true, :block => true) do |delivery_info, metadata, payload|
                @rx_queue << request_class.create_from_raw_message(delivery_info, metadata, payload)
                @rx_channel.ack(delivery_info.delivery_tag)
              end
            rescue Interrupt
              break
            rescue Exception => e
              ApiTools::Logger.error e
            end
          end
        end
      end

      def create_tx_thread
        @tx_thread = Thread.new do
          @tx_channel = @connection.create_channel

          @boot_queue << true
          loop do
            begin
              msg = @tx_queue.pop
              options = {
                :message_id => msg.message_id,
                :routing_key => msg.routing_key,
                :type => msg.type,
                :correlation_id => msg.correlation_id,
                :content_type => msg.content_type,
                :reply_to => msg.reply_to,
              }
              msg.serialize
              @tx_channel.default_exchange.publish(msg.payload, options)
            rescue Interrupt
              break
            rescue Exception => e
              ApiTools::Logger.error e
            end
          end
        end
      end

      def start
        @boot_queue.clear

        connect

        create_tx_thread
        create_rx_thread

        (1..@thread_count).each do |id|
          @worker_threads << create_worker_thread
        end

        begin
          Timeout::timeout(@timeout / 1000.0) do
            @boot_queue.pop
            @boot_queue.pop
          end
        rescue TimeoutError
          raise RuntimeError.new("Tx/Rx/Worker Threads did not start in a timely manner")
        end
      end

      def join
        @rx_thread.join
      end

      def stop
        @rx_thread.kill unless @rx_thread.nil?
        @tx_thread.kill unless @tx_thread.nil?
        @worker_threads.each { |thread| thread.kill } unless @worker_threads.nil?

        @rx_thread = @tx_thread = nil
        @worker_threads = []
      end

      def send_message(msg)
        @tx_queue << msg
      end

      private

      def self.number_of_processors
        if RUBY_PLATFORM =~ /linux/
          return `cat /proc/cpuinfo | grep processor | wc -l`.to_i
        elsif RUBY_PLATFORM =~ /darwin/
          return `sysctl -n hw.logicalcpu`.to_i
        elsif RUBY_PLATFORM =~ /win32/
          # this works for windows 2000 or greater
          require 'win32ole'
          wmi = WIN32OLE.connect("winmgmts://")
          wmi.ExecQuery("select * from Win32_ComputerSystem").each do |system|
            begin
              processors = system.NumberOfLogicalProcessors
            rescue
              processors = 0
            end
            return [system.NumberOfProcessors, processors].max
          end
        end
        raise "can't determine 'number_of_processors' for '#{RUBY_PLATFORM}'"
      end
    end
  end
end