require 'spec_helper'

class TestCORSServiceImplementation < ApiTools::ServiceImplementation
  def show( context )
    context.response.body = { 'show' => 'the thing', 'the_thing' => context.request.ident }
  end
end

class TestCORSServiceInterface < ApiTools::ServiceInterface
  interface :TestCORS do
    endpoint :test_cors, TestCORSServiceImplementation
    actions :show
  end
end

class TestCORSServiceApplication < ApiTools::ServiceApplication
  comprised_of TestCORSServiceInterface
end

describe ApiTools::ServiceMiddleware do
  def app
    Rack::Builder.new do
      use ApiTools::ServiceMiddleware
      run TestCORSServiceApplication.new
    end
  end

  context 'preflight' do
    it 'accepts a valid request' do
      origin = 'http://localhost'

      options '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8',
        'HTTP_ORIGIN' => origin,
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
      }

      expect(last_response.status).to eq(200)

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq(origin)
      expect(last_response.headers['Access-Control-Allow-Methods']).to eq('GET, POST, PATCH, DELETE')
      expect(last_response.headers['Access-Control-Allow-Headers']).to eq('X-Session-ID')
    end

    it 'refuses preflight without an Origin header' do
      options '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
      }

      expect(last_response.status).to eq(405)
    end

    it 'refuses unsupported methods' do
      options '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8',
        'HTTP_ORIGIN' => 'http://localhost',
        'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'PUT' # We use PATCH not PUT
      }

      expect(last_response.status).to eq(405)
    end

    it 'refuses requests for any special headers' do
      options '/v1/test_cors/hello', nil, {
        'CONTENT_TYPE' => 'application/json; charset=utf-8',
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
