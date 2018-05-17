require 'spec_helper'

describe Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter do
  class TestERBase < described_class
  end

  # The #communicate method is checked via exception_reporting_spec.rb.

  it 'is a singleton' do
    expect( TestERBase.instance ).to be_a( TestERBase )
  end

  it 'provides a reporting example' do
    expect {
      TestERBase.instance.report( RuntimeError.new )
    }.to raise_exception( RuntimeError, 'Subclasses must implement #report' )
  end

  it 'provides a contextual reporting example' do
    expect {
      TestERBase.instance.contextual_report( RuntimeError.new, nil )
    }.to raise_exception( RuntimeError, 'Subclasses may implement #contextual_report' )
  end

  context '#user_data_for' do

    class UserDataImplementation < Hoodoo::Services::Implementation
    end

    class UserDataInterface < Hoodoo::Services::Interface
      interface :UserData do
        version 2
        endpoint :user_data, UserDataImplementation
      end
    end

    before :each do

      # This requires a great big heap of setup to avoid lots of mocking
      # and keep the test reasonably meaningful.

      session = Hoodoo::Services::Middleware.test_session()
      request = Hoodoo::Services::Request.new

      request.locale              = 'en-nz'
      request.uri_path_components = [ 'path', 'subpath' ]
      request.uri_path_extension  = 'tar.gz'
      request.embeds              = [ 'e1', 'e2' ]
      request.references          = [ 'r1', 'r2' ]
      request.headers             = { 'HTTP_X_EXAMPLE' => '42' }
      request.list.offset         = 0
      request.list.limit          = 50
      request.list.sort_data      = { 'created_at' => 'desc' }
      request.list.search_data    = { 'example'    => '42'   }
      request.list.filter_data    = { 'unexample'  => '24'   }

      @mock_iid          = Hoodoo::UUID.generate()
      mock_env           = { 'HTTP_X_INTERACTION_ID' => @mock_iid }
      owning_interaction = Hoodoo::Services::Middleware::Interaction.new(
        mock_env,
        nil,
        session
      )

      owning_interaction.target_interface = UserDataInterface

      @context = Hoodoo::Services::Context.new(
        session,
        request,
        nil,
        owning_interaction
      )
    end

    it 'works' do
      hash = TestERBase.instance.send( :user_data_for, @context )
      expect( hash ).to eq(
        {
          :interaction_id => @mock_iid,
          :action         => '(unknown)',
          :resource       => 'UserData',
          :version        => 2,
          :request        => {
            :locale              => 'en-nz',
            :uri_path_components => [ 'path', 'subpath' ],
            :uri_path_extension  => 'tar.gz',
            :embeds              => [ 'e1', 'e2' ],
            :references          => [ 'r1', 'r2' ],
            :headers             => { 'HTTP_X_EXAMPLE' => '42' },
            :list                => {
              'offset'      => 0,
              'limit'       => 50,
              'sort_data'   => { 'created_at' => 'desc' },
              'search_data' => { 'example'    => '42'   },
              'filter_data' => { 'unexample'  => '24'   }
            }
          },
          :session => Hoodoo::Services::Middleware.test_session().to_h()
        }
      )
    end

    it 'returns "nil" for bad contexts' do
      @context.owning_interaction.target_interface = nil
      hash = TestERBase.instance.send( :user_data_for, @context )
      expect( hash ).to be_nil
    end
  end
end
