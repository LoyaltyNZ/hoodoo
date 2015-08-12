require 'spec_helper'

class TestCORSImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.body = { 'show' => 'the thing', 'the_thing' => context.request.ident }
  end
end

class TestCORSInterface < Hoodoo::Services::Interface
  interface :TestCORS do
    endpoint :test_cors, TestCORSImplementation
    actions :show
  end
end

class TestCORSService < Hoodoo::Services::Service
  comprised_of TestCORSInterface
end

describe Hoodoo::Services::Middleware do
  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run TestCORSService.new
    end
  end

  context 'preflight' do
    it 'accepts a valid request' do
      origin = 'http://localhost'

      options '/v1/test_cors/hello', nil, {
        'HTTP_ORIGIN' => origin,
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET',
        'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'Content-Type, X-SESSION_ID'
      }

      expect(last_response.status).to eq(200)

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq(origin)
      expect(last_response.headers['Access-Control-Allow-Methods']).to eq(Hoodoo::Services::Middleware::ALLOWED_HTTP_METHODS.to_a.join(', '))
      expect(last_response.headers['Access-Control-Allow-Headers']).to eq('Content-Type, X-SESSION_ID')
    end

    it 'refuses preflight without an Origin header' do
      options '/v1/test_cors/hello', nil, {
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
      }

      expect(last_response.status).to eq(405)
    end

    it 'refuses unsupported methods' do
      options '/v1/test_cors/hello', nil, {
        'HTTP_ORIGIN' => 'http://localhost',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'PUT' # We use PATCH not PUT
      }

      expect(last_response.status).to eq(405)
    end

    it 'refuses requests for any special headers' do
      options '/v1/test_cors/hello', nil, {
        'HTTP_ORIGIN' => 'http://localhost',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET',
        'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'X-Anything'
      }

      expect(last_response.status).to eq(405)
    end
  end

  context 'other request' do
    it 'quotes the origin' do
      origin = 'http://localhost'

      get '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8',
        'HTTP_ORIGIN' => origin
      }

      expect(last_response.status).to eq(200)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq(origin)
    end

    it 'understands non-CORS requests' do
      get '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8'
      }

      expect(last_response.status).to eq(200)
      expect(last_response.headers['Access-Control-Allow-Origin']).to be_nil
    end
  end

end
