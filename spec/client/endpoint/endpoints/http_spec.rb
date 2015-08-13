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

    class DataBreachError < RuntimeError
    end

    class SslSelfSignedApp
      def call(env)
        return [200, {'Content-Type' => 'application/json'}, ['{"message": "This data is a secret"}'] ]
      end
    end

    let(:ca_file) { 'spec/files/ca/ca-cert.pem' }
    let(:hostname) { '127.0.0.1' }

    before(:each) do
      # Start a service listenting on https 127.0.0.1 with a self-signed cert.
      @https_port = spec_helper_start_svc_app_in_thread_for(SslSelfSignedApp, true, skip_hoodoo_middleware: true)

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

      @endpoint = Hoodoo::Services::Middleware::InterResourceRemote.new(
        'SecureData',
        2,
        {
          :interaction      => interaction,
          :discovery_result => discovery_result
        }
      )
    end

    it 'should verify correctly' do
      response = @endpoint.list()
      expect(response["message"]).to eq("This data is a secret")
    end

    context "when cert doesn't match the hostname" do
      let(:hostname) { "localhost" } # localhost doesn't match the cert valid for 127.0.0.1

      it 'should raise an error' do
        response = @endpoint.list()
        expect(response.platform_errors.has_errors?).to eq(true)
        expect(response.platform_errors.errors.first["code"]).to eq("platform.fault")
      end
    end

    context "when the cert isn't in the ca_file trust store" do
      let(:ca_file) { nil } # Validation should fail, when we use the default trust-store

      it 'should raise an error' do
        response = @endpoint.list()
        expect(response.platform_errors.has_errors?).to eq(true)
        expect(response.platform_errors.errors.first["code"]).to eq("platform.fault")
      end
    end

  end

end
