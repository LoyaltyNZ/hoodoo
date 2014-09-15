require './lib/api_tools'

puts "Creating & Starting Client.."
client = ApiTools::Services::BaseClient.new("amqp://test:test@localhost:5672", :timeout => 5000)
client.start

puts "Sending Service Request Packet"
request, response = client.request('service.test','Tom Cully')
if request.timeout?
  puts "Request Timed Out"
else
  puts "Response: #{response.payload}"
end