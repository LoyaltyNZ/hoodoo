require './lib/api_tools'

class TestService2 < ApiTools::Services::BaseService
  def process(request)
    puts "service_backend Processing #{request.message_id}"
    if ARGV.count>0
      sleep ARGV[0].to_i
    end
    request.create_response({
      :payload => "Your name is #{request.payload}"
    })
  end
end

class TestService1 < ApiTools::Services::BaseService
  def process(request)
    puts "service_frontend Processing #{request.message_id}"
    backend_request, backend_response = request('service.test_backend', request.payload)

    request.create_response({
      :payload => "Forwarded: #{backend_response.payload}"
    })
  end
end

puts "Starting Services..."
service_backend = TestService2.new("amqp://test:test@localhost:5672","test_backend")
service_frontend = TestService1.new("amqp://test:test@localhost:5672","test")

service_backend.start
service_frontend.start

puts "Services Waiting For Requests"
service_frontend.join
service_backend.join