# This is a sort-of-integration test that ad hoc tests different elements of
# the stack already exercised elsewhere, especially in the middleware tests
# from service_middleware_spec.rb. It's just a different "angle" on everthing
# for a belt and braces approach.

require 'spec_helper'

class RSpecTestServiceAImplementation < ApiTools::ServiceImplementation
  def list( context )
    raise self.class.name + ' list'
  end

  def show( context )
    raise self.class.name + ' show'
  end

  def create( context )
    raise self.class.name + ' create'
  end

  def update( context )
    raise self.class.name + ' update'
  end

  def delete( context )
    raise self.class.name + ' delete'
  end
end

class RSpecTestServiceAInterface < ApiTools::ServiceInterface
  interface :RSpecTestService do
    endpoint :rspec_test_service_a, RSpecTestServiceAImplementation
  end
end

class RSpecTestServiceA < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceAInterface
end

describe RSpecTestServiceA do
  describe 'when badly configured' do
    context 'with no middleware' do
      def app
        Rack::Builder.new do
          # The deliberate mistake - no 'use ...' telling Rack about
          # the service middleware...
          run RSpecTestServiceA.new
        end
      end

      it 'should complain about being called directly' do
        expect {
          get '/v1/rspec_test_service_a'
        }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'when well configured' do
    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run RSpecTestServiceA.new
      end
    end

    # This batch of tests doesn't worry about middleware-level rejection of
    # bad requests and so-on as the middleware specs catch that. It just wants
    # to make sure that a top-end get/post/patch/delete gets routed down to
    # the correct action method in the correct implementation.

    it 'should list items' do
      get '/v1/rspec_test_service_a', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('RSpecTestServiceAImplementation list')
    end

    it 'should show an item' do
      get '/v1/rspec_test_service_a/foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('RSpecTestServiceAImplementation show')
    end

    it 'should create an item' do
      post '/v1/rspec_test_service_a/', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('RSpecTestServiceAImplementation create')
    end

    it 'should update an item' do
      patch '/v1/rspec_test_service_a/foo', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('RSpecTestServiceAImplementation update')
    end

    it 'should delete an item' do
      delete '/v1/rspec_test_service_a/foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('RSpecTestServiceAImplementation delete')
    end
  end
end
