require './lib/api_tools'
require 'sinatra'

set :port, 3250

puts "Creating & Starting Edge Splitter Client.."
client = ApiTools::Services::BaseClient.new("amqp://test:test@localhost:5672")
client.start

before do
  request.body.rewind
  @payload = request.body.read

  content_type 'application/json; charset=utf-8'
end

post '/*' do
  request, response = client.request('service.test', @payload)

  halt 408 if request.timeout?

  return response.payload
end
