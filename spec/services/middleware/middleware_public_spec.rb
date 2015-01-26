# service_middleware_spec.rb is already large, so split out tests related
# explicitly to public actions in interfaces here.

require 'spec_helper'

# Create three service applications. The first has one interface with no public
# actions. The second has one interface with a public and private action. The
# last contains both interfaces.

class TestNoPublicActionImplementation < Hoodoo::Services::Implementation
  def list( context )
    context.response.set_resources( [ { 'private' => true } ] )
  end

  def show( context )
    context.response.set_resources( { 'private' => true } )
  end
end

class TestPublicActionImplementation < Hoodoo::Services::Implementation
  def list( context )
    context.response.set_resources( [ { 'public' => true } ] )
  end

  def show( context )
    context.response.set_resources( { 'public' => true } )
  end
end

class TestNoPublicActionInterface < Hoodoo::Services::Interface
  interface :NoPublicAction do
    endpoint :no_public_action, TestNoPublicActionImplementation
    actions :show, :list
  end
end

class TestPublicActionInterface < Hoodoo::Services::Interface
  interface :PublicAction do
    endpoint :public_action, TestPublicActionImplementation
    actions :show, :list
    public_actions :list
  end
end

class TestNoPublicActionService < Hoodoo::Services::Service
  comprised_of TestNoPublicActionInterface
end

class TestPublicActionService < Hoodoo::Services::Service
  comprised_of TestPublicActionInterface
end

class TestMixPublicActionService < Hoodoo::Services::Service
  comprised_of TestNoPublicActionInterface,
               TestPublicActionInterface
end

# Run the tests

describe Hoodoo::Services::Middleware do

  def try_to_call( endpoint, ident = nil )
    get(
      "/v1/#{ endpoint }/#{ ident }",
      nil,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    )
  end

  before :example, :without_session => true do
    expect( Hoodoo::Services::Session ).to receive( :load_session ).once.and_return( nil )
  end

  # -------------------------------------------------------------------------

  context 'with only secure actions' do

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run TestNoPublicActionService.new
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
        use Hoodoo::Services::Middleware
        run TestPublicActionService.new
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

    # Middleware maintains class-level record of whether or not any interfaces
    # had public actions for efficiency; ensure this is cleared after all these
    # tests run, so it's a clean slate for the next set.
    #
    after :all do
      Hoodoo::Services::Middleware::class_variable_set( '@@interfaces_have_public_methods', false )
    end

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run TestMixPublicActionService.new
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
