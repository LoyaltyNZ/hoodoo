require 'spec_helper.rb'
require 'timecop'

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

    @identity_id_1    = Hoodoo::UUID.generate
    @identity_id_2    = Hoodoo::UUID.generate
    @identity_id_3    = Hoodoo::UUID.generate

    @authorised_ids   = [ Hoodoo::UUID.generate, Hoodoo::UUID.generate ]
    @authorised_codes = [ 'CODE_A', 'CODE_B' ]

    @session.identity = {
      :id_1 => @identity_id_1,
      :id_2 => @identity_id_2,
      :id_3 => @identity_id_3,
    }

    @session.scoping = {
      :authorised_ids   => @authorised_ids,
      :authorised_codes => @authorised_codes
    }

    @alchemy = OpenStruct.new
    @queue   = 'foo.bar'
    @logger  = described_class.new( @alchemy, @queue )
  end

  it 'sends expected data' do
    Timecop.freeze do
      level          = 'warn'
      component      = 'test_component'
      code           = 'test_code'
      reported_at    = Time.now.strftime( Hoodoo::Services::Middleware::AMQPLogMessage::TIME_FORMATTER )
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
        :reported_at    => reported_at,

        :data           => data,

        :interaction_id => interaction_id,
        :caller_id      => @session.caller_id,
        :client_id      => @session.caller_id,
        :identity       => Hoodoo::Utilities.stringify( @session.identity.to_h ),

        :routing_key    => @queue,
      }

      expect( Hoodoo::Services::Middleware::AMQPLogMessage ).to receive( :new ).with( expected_hash ).and_return( {} )
      expect( @alchemy ).to receive( :send_message ).with( {} ).once

      @logger.report( level, component, code, data )
    end
  end
end
