# This is a sort-of-integration test that ad hoc tests different elements of
# the stack already exercised elsewhere, especially in the middleware tests
# from service_middleware_spec.rb. It's just a different "angle" on everthing
# for a belt and braces approach.

require 'spec_helper'

class RSpecTestServiceAImplementation < ApiTools::ServiceImplementation
  def list( request, response )
  end

  def show( request, response )
  end

  def create( request, response )
  end

  def update( request, response )
  end

  def delete( request, response )
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

    it 'should list items' do
      get '/v1/rspec_test_service_a'
      expect(last_response.status).to eq(200)
    end
  end
end
