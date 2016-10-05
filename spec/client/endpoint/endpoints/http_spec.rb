require 'spec_helper'

# Much of this class gets nontrivial coverage from middleware tests, which
# existed before the refactor of code from there, into Endpoints.
#
# This file just picks up the loose ends.

describe Hoodoo::Client::Endpoint::HTTP do

  it 'complains if instantiated with the wrong discovery result type' do
    expect {
      described_class.new( :Anything, 1, { :discovery_result => OpenStruct.new } )
    }.to raise_error( RuntimeError, "Hoodoo::Client::Endpoint::HTTP must be configured with a Hoodoo::Services::Discovery::ForHTTP instance - got 'OpenStruct'" )
  end

  context 'SSL Cert chain verification' do

    before(:all) do
      # Start a service listening on https 127.0.0.1 with a self-signed cert.
      #
      # Note: we are skipping hoodoo middleware with +skip_hoodoo_middleware+
      # because this test is about verifying SSL on the client, and we need
      # to be certain that any errors thrown are from client, and not from
      # middleware (e.g. server).
      #
      # This test effectively ensures we aren't vulnerable to a MiTM attack, and malicious parties
      # won't be good upstanding Hoodoo::Middleware using citizens.
      #
      @https_port = spec_helper_start_svc_app_in_thread_for(SslSelfSignedApp, true, skip_hoodoo_middleware: true)
    end

    it 'should successfuly connect with valid certificate chain' do
      endpoint = connect_to_real_https_endpoint('127.0.0.1', 'spec/files/ca/ca-cert.pem')
      response = endpoint.list()
      expect(response[0]["message"]).to eq("This data is a secret")
    end

    it "should fail when certificate doesn't match the hostname" do
      endpoint = connect_to_real_https_endpoint('localhost', 'spec/files/ca/ca-cert.pem')
      response = endpoint.list()
      expect(response.platform_errors.has_errors?).to eq(true)
      expect(response.platform_errors.errors.first["code"]).to eq("platform.fault")
    end

    it "should fail when the certificate isn't in the ca_file" do
      endpoint = connect_to_real_https_endpoint('127.0.0.1', nil)
      response = endpoint.list()
      expect(response.platform_errors.has_errors?).to eq(true)
      expect(response.platform_errors.errors.first["code"]).to eq("platform.fault")
    end

    class SslSelfSignedApp
      def call(env)
        # Note: Respond to 'list' calls with correct Hoodoo semantics
        return [200, {'Content-Type' => 'application/json'}, ['{ "_data" : [ { "message": "This data is a secret" } ] }'] ]
      end
    end

    def connect_to_real_https_endpoint(hostname, ca_file)
      mw = SslSelfSignedApp.new
      interaction = Hoodoo::Services::Middleware::Interaction.new(
        {},
        mw,
        Hoodoo::Services::Middleware.test_session()
      )
      interaction.target_interface = OpenStruct.new

      mock_wrapped_discovery_result = Hoodoo::Services::Discovery::ForHTTP.new(
        resource:     'SecureData',
        version:      2,
        endpoint_uri: URI.parse( "https://#{hostname}:#{ @https_port }/v2/secure_data" ),
        ca_file:      ca_file
      )

      mock_wrapped_endpoint = Hoodoo::Client::Endpoint::HTTP.new(
        'SecureData',
        2,
        :session => Hoodoo::Services::Middleware.test_session(),
        :discovery_result => mock_wrapped_discovery_result
      )

      # Synthesise a remote resource discovery result for the HTTP(S) endpoint
      # built above and use that to make a remote call endpoint.

      discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
        :resource         => 'SecureData',
        :version          => 2,
        :wrapped_endpoint => mock_wrapped_endpoint
      )

      endpoint = Hoodoo::Services::Middleware::InterResourceRemote.new(
        'SecureData',
        2,
        {
          :interaction      => interaction,
          :discovery_result => discovery_result
        }
      )
      return endpoint
    end

  end

end
