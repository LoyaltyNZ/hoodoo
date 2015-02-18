require 'spec_helper.rb'

describe Hoodoo::Services::Middleware::AMQPLogWriter do
  before :each do
    @session_id     = Hoodoo::UUID.generate
    @caller_id      = Hoodoo::UUID.generate
    @caller_version = 2
    @session        = Hoodoo::Services::Session.new( {
      :session_id     => @session_id,
      :memcached_host => '0.0.0.0:0',
      :caller_id      => @caller_id,
      :caller_version => @caller_version
    } )

    @permissions_hash = {
      'default' => {
        'else' => 'deny',
        'actions' => {
          'show' => 'ask'
        }
      },
      'resources' => {
        'Clock' => {
          'else' => 'allow',
          'actions' => {
            'show' => 'deny'
          }
         }
       }
     }

    @session.permissions = Hoodoo::Services::Permissions.new( @permissions_hash )

    @participant_id = Hoodoo::UUID.generate
    @outlet_id      = Hoodoo::UUID.generate

    @authorised_participant_ids = [ Hoodoo::UUID.generate, Hoodoo::UUID.generate ]
    @authorised_programme_codes = [ 'PRG_A', 'PRG_B' ]

    @session.identity = {
      :participant_id => @participant_id,
      :outlet_id      => @outlet_id
    }

    @session.scoping = {
      :authorised_participant_ids => @authorised_participant_ids,
      :authorised_programme_codes => @authorised_programme_codes
    }

    @alchemy = OpenStruct.new
    @queue   = 'foo.bar'
    @logger  = described_class.new( @alchemy, @queue )
  end

  it 'sends expected data' do
    level          = 'warn'
    component      = 'test_component'
    code           = 'test_code'
    id             = Hoodoo::UUID.generate
    interaction_id = Hoodoo::UUID.generate
    data           = {
      :id             => id,
      :session        => @session.to_h(),
      :interaction_id => interaction_id
    }

    expected_hash  = {
      :id             => id,
      :level          => 'warn',
      :component      => component,
      :code           => code,

      :data           => data,

      :caller_id      => @session.caller_id,
      :interaction_id => interaction_id,
      :participant_id => @session.identity.participant_id,
      :outlet_id      => @session.identity.outlet_id,

      :routing_key    => @queue,
    }

    expect( Hoodoo::Services::Middleware::AMQPLogMessage ).to receive( :new ).with( expected_hash ).and_return( {} )
    expect( @alchemy ).to receive( :send_message ).with( {} ).once

    @logger.report( level, component, code, data )
  end
end
