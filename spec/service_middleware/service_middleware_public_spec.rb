# service_middleware_spec.rb is already large, so split out tests related
# explicitly to public actions in interfaces here.

require 'spec_helper'

# Create three service applications. The first has one interface with no public
# actions. The second has one interface with a public and private action. The
# last contains both interfaces.

class TestNoPublicActionServiceImplementation < ApiTools::ServiceImplementation
  def list( context )
    context.response.set_resources( [ { 'private' => true } ] )
  end

  def show( context )
    context.response.set_resources( { 'private' => true } )
  end
end

class TestPublicActionServiceImplementation < ApiTools::ServiceImplementation
  def list( context )
    context.response.set_resources( [ { 'public' => true } ] )
  end

  def show( context )
    context.response.set_resources( { 'public' => true } )
  end
end

class TestNoPublicActionServiceInterface < ApiTools::ServiceInterface
  interface :NoPublicAction do
    endpoint :no_public_action, TestNoPublicActionServiceImplementation
    actions :show, :list
  end
end

class TestPublicActionServiceInterface < ApiTools::ServiceInterface
  interface :PublicAction do
    endpoint :public_action, TestPublicActionServiceImplementation
    actions :show, :list
    public_actions :list
  end
end

class TestNoPublicActionServiceApplication < ApiTools::ServiceApplication
  comprised_of TestNoPublicActionServiceInterface
end

class TestPublicActionServiceApplication < ApiTools::ServiceApplication
  comprised_of TestPublicActionServiceInterface
end

class TestMixPublicActionServiceApplication < ApiTools::ServiceApplication
  comprised_of TestNoPublicActionServiceInterface,
               TestPublicActionServiceInterface
end

# Run the tests

describe ApiTools::ServiceMiddleware do

  def try_to_call( endpoint, ident = nil )
    get(
      "/v1/#{ endpoint }/#{ ident }",
      nil,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    )
  end

  before :example, :without_session => true do
    expect( ApiTools::ServiceSession ).to receive( :load_session ).once.and_return( nil )
  end

  # -------------------------------------------------------------------------

  context 'with only secure actions' do

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestNoPublicActionServiceApplication.new
      end
    end

    context '#list' do
      it 'prohibits actions without session', :without_session => true do
        try_to_call( 'no_public_action' )
        expect( last_response.status ).to eq( 401 )
      end

      it 'allows actions with session' do
        try_to_call( 'no_public_action' )
        expect( last_response.status ).to eq( 200 )
      end
    end

    context '#show' do
      it 'prohibits actions without session', :without_session => true do
        try_to_call( 'no_public_action', 'some_uuid' )
        expect( last_response.status ).to eq( 401 )
      end

      it 'allows actions with session' do
        try_to_call( 'no_public_action', 'some_uuid' )
        expect( last_response.status ).to eq( 200 )
      end
    end
  end

  # -------------------------------------------------------------------------

  context 'with a public action' do

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestPublicActionServiceApplication.new
      end
    end

    it 'prohibits secure actions without session', :without_session => true do
      try_to_call( 'public_action', 'some_uuid' )
      expect( last_response.status ).to eq( 401 )
    end

    it 'allows secure actions with session' do
      try_to_call( 'public_action', 'some_uuid' )
      expect( last_response.status ).to eq( 200 )
    end

    it 'allows public actions without session', :without_session => true do
      try_to_call( 'public_action' )
      expect( last_response.status ).to eq( 200 )
    end

    it 'allows public actions with session' do
      try_to_call( 'public_action' )
      expect( last_response.status ).to eq( 200 )
    end
  end

  # -------------------------------------------------------------------------

  context 'with mixed access across interfaces' do

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestMixPublicActionServiceApplication.new
      end
    end

    context 'in interface with no public actions' do
      context '#list' do
        it 'prohibits actions without session', :without_session => true do
          try_to_call( 'no_public_action' )
          expect( last_response.status ).to eq( 401 )
        end

        it 'allows actions with session' do
          try_to_call( 'no_public_action' )
          expect( last_response.status ).to eq( 200 )
        end
      end

      context '#show' do
        it 'prohibits actions without session', :without_session => true do
          try_to_call( 'no_public_action', 'some_uuid' )
          expect( last_response.status ).to eq( 401 )
        end

        it 'allows actions with session' do
          try_to_call( 'no_public_action', 'some_uuid' )
          expect( last_response.status ).to eq( 200 )
        end
      end
    end

    context 'in interface with public actions' do
      it 'prohibits secure actions without session', :without_session => true do
        try_to_call( 'public_action', 'some_uuid' )
        expect( last_response.status ).to eq( 401 )
      end

      it 'allows secure actions with session' do
        try_to_call( 'public_action', 'some_uuid' )
        expect( last_response.status ).to eq( 200 )
      end

      it 'allows public actions without session', :without_session => true do
        try_to_call( 'public_action' )
        expect( last_response.status ).to eq( 200 )
      end

      it 'allows public actions with session' do
        try_to_call( 'public_action' )
        expect( last_response.status ).to eq( 200 )
      end
    end
  end

  # -------------------------------------------------------------------------

end
