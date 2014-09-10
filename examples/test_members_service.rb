require './lib/api_tools'

class MembersService < ApiTools::Services::BaseService
  def process(request)
    puts "Processing Message Id: #{metadata.message_id}"
    if ARGV.count>0
      sleep ARGV[0].to_i
    end
    request.create_response({
      :payload => JSON.fast_generate({
        :members => [
          { :id => '8rwew492492', :name => 'Tom' },
          { :id => '34523423432', :name => 'Marcus' },
          { :id => '45645645654', :name => 'Andrew' },
          { :id => '3gerwveverg', :name => 'Graham' },
        ]
      }),
    })
  end
end

puts "Creating Members Service"
service = MembersService.new("amqp://test:test@localhost:5672","members")

puts "Waiting For Requests, ID: #{service.endpoint_id}"
service.start

service.join