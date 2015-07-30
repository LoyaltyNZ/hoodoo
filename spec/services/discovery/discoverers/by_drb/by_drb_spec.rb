require 'spec_helper'

# A lot of this class is already covered by tests elsewhere, e.g. the
# drb_server_spec.rb stuff (via the middleware integration test part).

describe Hoodoo::Services::Discovery::ByDRb do

  # Shut down a DRb service expected to be running (in a thread) on
  # the given port.
  #
  def shut_down_drb_service_on( port )

    # Don't use Ruby Timeout here. Pseudorandom apparent DRb
    # connection issues will arise, especially in Travis.
    #
    # https://flushentitypacket.github.io/ruby/2015/02/21/ruby-timeout-how-does-it-even-work.html
    # https://coderwall.com/p/1novga/ruby-timeouts-are-dangerous

    counter = 0
    limit   = 10000 # sleep 0.1 * 100 => roughly 10 seconds

    loop do
      begin
        client = DRbObject.new_with_uri( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri( port ) )
        client.ping()
        client.stop()
        break
      rescue DRb::DRbConnError
        counter += 1
        if counter > limit
          raise "Timed out while waiting for DRb service on local port #{ port } to shut down"
        end
        sleep 0.1
      end
    end
  end

  # This also tests in passing specifying a port number right through
  # the discoverer to the CLI script that starts a DRb server up.
  #
  # If you get timeouts from the test, it's likely that the port number
  # hasn't reached the server startup script and the server has come up
  # on a different port.
  #
  it 'runs a DRb service which can be pinged and shuts down' do
    expect {
      port = Hoodoo::Utilities.spare_port().to_s

      discoverer = Hoodoo::Services::Discovery::ByDRb.new( :drb_port => port )
      discoverer.announce( :Foo, 1, :host => '127.0.0.1', :port => '9292' )

      shut_down_drb_service_on( port )
    }.to_not raise_error
  end

  # Similar to the above, but this tests passing in a full URI and assuming
  # that the service is already running.
  #
  it 'can contact an existing DRb server' do
    expect {
      port = Hoodoo::Utilities.spare_port().to_s

      discoverer = Hoodoo::Services::Discovery::ByDRb.new( :drb_port => port )
      discoverer.announce( :Foo, 1, :host => '127.0.0.1', :port => '9292' )

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
