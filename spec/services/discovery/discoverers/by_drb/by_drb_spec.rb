require 'spec_helper'

# A lot of this class is already covered by tests elsewhere, e.g. the
# drb_server_spec.rb stuff (via the middleware integration test part).

describe Hoodoo::Services::Discovery::ByDRb do

  # Shut down a DRb service expected to be running (in a thread) on
  # the given port.
  #
  def shut_down_drb_service_on( port )
    begin
      Timeout::timeout( 5 ) do
        loop do
          begin
            client = DRbObject.new_with_uri( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri( port ) )
            sleep 0.1
            client.ping()
            sleep 0.1
            client.stop()
            break
          rescue DRb::DRbConnError
            sleep 0.1
          end
        end
      end
    rescue Timeout::Error
      raise "Timed out while waiting for DRb service to communicate"
    end
  end

  # This also tests in passing specifying a port number right through
  # the discoverer to the CLI script that starts a DRb server up.
  #
  # If you get timeouts from the test, it's likely that the port number
  # hasn't reached the server startup script and the server has come up
  # on a different port.
  #
  it 'runs a DRb service in a thread which can be pinged and shuts down' do
    expect {
      port = Hoodoo::Utilities.spare_port().to_s

      thread = Thread.new do
        discoverer = Hoodoo::Services::Discovery::ByDRb.new( :drb_port => port )
        discoverer.announce( :Foo, 1, :host => '127.0.0.1', :port => '9292' )
      end

      shut_down_drb_service_on( port )
    }.to_not raise_error
  end

  # Similar to the above, but this tests passing in a full URI and assuming
  # that the service is already running.
  #
  it 'can contact an existing DRb server' do
    expect {
      port = Hoodoo::Utilities.spare_port().to_s
      $sync_queue = Queue.new

      thread = Thread.new do
        discoverer = Hoodoo::Services::Discovery::ByDRb.new( :drb_port => port )
        discoverer.announce( :Foo, 1, :host => '127.0.0.1', :port => '9292' )
        $sync_queue << :go!
      end

      # Have to wait for it to start and have the service announcement
      # made, before querying it.

      begin
        Timeout::timeout( 5 ) do
          loop do
            begin
              $sync_queue.pop( true )
              break
            rescue ThreadError
              sleep 0.1
            end
          end
        end
      rescue Timeout::Error
        raise "Timed out while waiting for DRb server thread to run"
      end

      discoverer = Hoodoo::Services::Discovery::ByDRb.new(
        :drb_uri => Hoodoo::Services::Discovery::ByDRb::DRbServer.uri( port )
      )

      expect( discoverer.discover( :Foo, 1 ) ).to be_a( Hoodoo::Services::Discovery::ForHTTP )

      shut_down_drb_service_on( port )
    }.to_not raise_error
  end

  it 'complains if it cannot contact an existing DRb server' do
    port = Hoodoo::Utilities.spare_port().to_s
    uri  = Hoodoo::Services::Discovery::ByDRb::DRbServer.uri( port )

    expect {
      discoverer = Hoodoo::Services::Discovery::ByDRb.new( :drb_uri => uri )
      discoverer.discover( :Foo, 1 )
    }.to raise_error(
      RuntimeError,
      "Hoodoo::Services::Discovery::ByDRb could not contact a DRb service registry at #{ uri }"
    )
  end
end
