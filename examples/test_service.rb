require './lib/api_tools'

class TestService < ApiTools::Services::BaseService
  def process(request)
    puts "Processing #{request}"
    if ARGV.count>0
      service.delay = ARGV[0].to_i
    end
    response = request.create_response({
      :payload => "Your name is #{request.payload}"
    })
    response
  end
end

puts "Creating Service!!"
service = TestService.new("amqp://test:test@localhost:5672","test")

puts "Waiting For Requests, ID: #{service.endpoint_id}"
service.start

service.join