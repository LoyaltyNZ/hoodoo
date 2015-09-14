# This unavoidably combines a lot of elements of integration testing since
# little of the middleware is really usable in isolation. We could test its
# component methods individually, but the interesting ones are all part of
# request processing anyway. Code coverage lets us know if we missed any
# internal methods when testing the request processing flow.

require 'spec_helper'


###############################################################################
# Single endpoint
###############################################################################


class RSpecTestServiceStubImplementation < Hoodoo::Services::Implementation
end

class RSpecTestServiceStubBeforeAfterImplementation < Hoodoo::Services::Implementation
  def before(context)
  end

  def after(context)
  end
end

class RSpecTestServiceStubInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_stub, RSpecTestServiceStubImplementation
    embeds :emb, :embs
    to_list do
      sort :extra => [:up, :down]
      search :foo, :bar
      filter :baz, :boo
    end
    to_create do
      text :foo, :required => true
      integer :bar
    end
    to_update do
      text :baz
      integer :foo, :required => true
    end
  end
end

class RSpecTestMatchingServiceStubInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_stub, RSpecTestServiceStubImplementation
  end
end

class RSpecTestServiceStubBeforeInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_before_after_stub, RSpecTestServiceStubBeforeAfterImplementation
    embeds :emb, :embs
    to_list do
      sort :extra => [:up, :down]
      search :foo, :bar
      filter :baz, :boo
    end
  end
end

class RSpecTestServiceStub < Hoodoo::Services::Service
  comprised_of RSpecTestServiceStubInterface, RSpecTestServiceStubBeforeInterface
end

describe Hoodoo::Services::Middleware do

  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecTestServiceStub.new
    end
  end

  context 'internal sanity checks' do
    it 'should complain about bad instantiation' do
      expect {
        Hoodoo::Services::Middleware.new( {} )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Middleware instance created with non-Service entity of class 'Hash' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?")
    end

    it 'should complain about bad instantiation due to bad NewRelic' do
      expect {
        module NewRelic
          module Agent
            module Instrumentation
              class MiddlewareProxy
              end
            end
          end
        end

        Hoodoo::Services::Middleware.new( NewRelic::Agent::Instrumentation::MiddlewareProxy.new )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Middleware instance created with NewRelic-wrapped Service entity, but NewRelic API is not as expected by Hoodoo; incompatible NewRelic version.")

      Object.send( :remove_const, :NewRelic )
    end

    it 'should complain about bad instantiation via NewRelic' do
      expect {
        module NewRelic
          module Agent
            module Instrumentation
              class MiddlewareProxy
                def target
                  {}
                end
              end
            end
          end
        end

        Hoodoo::Services::Middleware.new( NewRelic::Agent::Instrumentation::MiddlewareProxy.new )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Middleware instance created with non-Service entity of class 'Hash' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?")

      Object.send( :remove_const, :NewRelic )
    end

    it 'should complain about bad applications directly or via NewRelic' do
      class RSpecTestServiceStubBadInterface < Hoodoo::Services::Interface
      end
      class RSpecTestServiceStubBad < Hoodoo::Services::Service
        comprised_of RSpecTestServiceStubBadInterface
      end

      expect {
        Hoodoo::Services::Middleware.new( RSpecTestServiceStubBad.new )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Middleware encountered invalid interface class RSpecTestServiceStubBadInterface via service class RSpecTestServiceStubBad")

      expect {
        module NewRelic
          module Agent
            module Instrumentation
              class MiddlewareProxy
                def target
                  RSpecTestServiceStubBad.new
                end
              end
            end
          end
        end

        Hoodoo::Services::Middleware.new( NewRelic::Agent::Instrumentation::MiddlewareProxy.new )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Middleware encountered invalid interface class RSpecTestServiceStubBadInterface via service class RSpecTestServiceStubBad")

      Object.send( :remove_const, :NewRelic )
    end

    it 'should self-check content type' do
      mw = Hoodoo::Services::Middleware.new( RSpecTestServiceStub.new )
      interaction = Hoodoo::Services::Middleware::Interaction.new( {}, mw )
      interaction.requested_content_type = 'application/xml'
      expect {
        mw.send( :parse_body_string_into, interaction, '{}' )
      }.to raise_error(RuntimeError, "Internal error - content type 'application/xml' is not supported here; \#deal_with_content_type_header() should have caught that");
    end

    it 'should detect a local versus remote endpoint mismatch' do
      mw = Hoodoo::Services::Middleware.new( RSpecTestServiceStub.new )
      interaction = Hoodoo::Services::Middleware::Interaction.new( {}, mw )

      mock_discoverer = OpenStruct.new
      mw.instance_variable_set( '@discoverer', mock_discoverer )
      expect( mock_discoverer ).to receive( :is_local? ).and_return( true )

      expect {
        mw.send( :inter_resource_endpoint_for, :NotALocalResource, 1, interaction )
      }.to raise_error(RuntimeError, 'Hoodoo::Services::Middleware#inter_resource_endpoint_for: Internal error - version 1 of resource NotALocalResource endpoint is local according to the discovery engine, but no local service discovery record can be found')
    end
  end

  context 'utility methods' do
    it 'should know about Memcached via environment variable' do
      old = ENV[ 'MEMCACHED_HOST' ]
      ENV[ 'MEMCACHED_HOST' ] = nil
      expect(Hoodoo::Services::Middleware.has_memcached?).to eq(false)
      ENV[ 'MEMCACHED_HOST' ] = 'foo'
      expect(Hoodoo::Services::Middleware.has_memcached?).to eq(true)
      ENV[ 'MEMCACHED_HOST' ] = old
    end

    it 'should know about Memcached via legacy environment variable' do
      old = ENV[ 'MEMCACHED_HOST' ]
      ENV[ 'MEMCACHED_HOST' ] = nil
      expect(Hoodoo::Services::Middleware.has_memcached?).to eq(false)
      ENV[ 'MEMCACHED_HOST' ] = 'foo'
      expect(Hoodoo::Services::Middleware.has_memcached?).to eq(true)
      ENV[ 'MEMCACHED_HOST' ] = old
    end

    it 'should know about a queue' do
      old = ENV[ 'AMQ_ENDPOINT' ]
      ENV[ 'AMQ_ENDPOINT' ] = nil
      expect(Hoodoo::Services::Middleware.on_queue?).to eq(false)
      ENV[ 'AMQ_ENDPOINT' ] = 'foo'
      expect(Hoodoo::Services::Middleware.on_queue?).to eq(true)
      ENV[ 'AMQ_ENDPOINT' ] = old
    end
  end

  context 'malformed basics in requests' do

    it 'should complain about entirely missing content type' do
      get '/v2/rspec_test_service_stub'

      expect(last_response.status).to eq(422)

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
      expect(result['errors'][0]['message']).to eq("Content-Type '<unknown>' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'")
    end

    it 'should complain about missing charset' do
      get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
      expect(result['errors'][0]['message']).to eq("Content-Type 'application/json' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'")
    end

    it 'should complain about incorrect content type' do
      get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'some/thing; charset=utf-8' }

      expect(last_response.status).to eq(422)

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
      expect(result['errors'][0]['message']).to eq("Content-Type 'some/thing; charset=utf-8' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'")
    end

    it 'should complain about incorrect content type' do
      get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=madeup' }

      expect(last_response.status).to eq(422)

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
      expect(result['errors'][0]['message']).to eq("Content-Type 'application/json; charset=madeup' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'")
    end

    it 'should generate interaction IDs and other standard headers even for error states' do
      get '/v2/rspec_test_service_stub'

      expect(last_response.status).to eq(422)
      expect(last_response.headers['X-Interaction-ID']).to_not be_nil
      expect(last_response.headers['X-Interaction-ID'].size).to eq(32)
      expect(last_response.headers['Content-Type']).to eq('application/json; charset=utf-8')
    end

  end

  context 'sessions' do

    # This leans on assumption that Permissions#permitted? has already
    # got adequate test coverage elsewhere, so we just make sure that
    # it seems to allow or deny as expected via the session.

    context 'present' do
      it 'should check for session permissions' do
        expect_any_instance_of(Hoodoo::Services::Session).to receive(:permissions).at_least( 1 ).times.and_call_original
        expect_any_instance_of(Hoodoo::Services::Permissions).to receive(:permitted?).at_least( 1 ).times.and_call_original
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once.and_return([])
        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end
    end

    context 'with restricted permissions' do
      before :example do
        @old_test_session = Hoodoo::Services::Middleware.test_session()
        test_session = @old_test_session.dup
        permissions = Hoodoo::Services::Permissions.new # (this is "default-else-deny")
        permissions.set_resource( :RSpecTestResource, :list, Hoodoo::Services::Permissions::ALLOW )
        permissions.set_resource( :RSpecTestResource, :show, Hoodoo::Services::Permissions::ASK )
        test_session.permissions = permissions
        Hoodoo::Services::Middleware.set_test_session( test_session )
      end

      after :example do
        Hoodoo::Services::Middleware.set_test_session( @old_test_session )
      end

      it 'denies' do
        delete '/v2/rspec_test_service_stub/uuid', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(403)
      end

      it 'allows' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once.and_return([])
        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'asks' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:verify).once.and_return(Hoodoo::Services::Permissions::ALLOW)
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once.and_return({})
        get '/v2/rspec_test_service_stub/uuid', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end
    end

    context 'absent' do
      before :example do
        @old_test_session = Hoodoo::Services::Middleware.test_session()
        Hoodoo::Services::Middleware.set_test_session( nil )
      end

      after :example do
        Hoodoo::Services::Middleware.set_test_session( @old_test_session )
      end

      it 'should check for missing session data' do
        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(401)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.invalid_session')
      end
    end

  end

  context 'well formed request for' do

    it 'no matching endpoint should return 404 with lower case in content type' do
      get '/v2/where_are_you', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(404)
    end

    it 'no matching endpoint should return 404 with mixed case in content type' do
      get '/v2/where_are_you', nil, { 'CONTENT_TYPE' => 'APPLICATION/json; charset=UTF-8' }
      expect(last_response.status).to eq(404)
    end

    it 'a matching endpoint should use fallback exception handler if early failures occur' do

      # Stub out anything early in request handling inside call() and make it
      # throw an exception.

      expect_any_instance_of(Hoodoo::Services::Middleware).to receive(:debug_log).and_raise("boo!")
      expect_any_instance_of(Hoodoo::Services::Middleware).to receive(:record_exception).and_raise("boo!")

      get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      expect(last_response.status).to eq(500)
      expect(last_response.body).to include('Middleware exception in exception handler')
    end

    it 'a matching endpoint should use fallback exception handler if the primary handler fails' do

      # This implicitly tests that Hoodoo' exception handler checks for test
      # and development mode and if both are false, calls the exception reporter.
      #
      # So, first, these are part of routine processing.

      expect(Hoodoo::Services::Middleware.environment).to receive(:test?).exactly(2).times.and_return(true)

      # The check for 'unless test or development' is made prior to trying to use
      # the ExceptionReporter class, so say 'no' to both then get the reporter to
      # itself raise an error.

      expect(Hoodoo::Services::Middleware.environment).to receive(:test?).once.and_return(false)
      expect(Hoodoo::Services::Middleware.environment).to receive(:development?).and_return(false)
      expect(Hoodoo::Services::Middleware::ExceptionReporting).to receive(:report).and_raise("boo!")

      # The inner handler checks for test/development to see it it should include
      # backtraces.

      expect(Hoodoo::Services::Middleware.environment).to receive(:test?).once.and_return(false)
      expect(Hoodoo::Services::Middleware.environment).to receive(:development?).and_return(false)

      # Route through to the unimplemented "list" call, so the subclass raises
      # an exception. This is tested independently elsewhere too. This causes
      # the normal exception handler to run, which breaks because of the above
      # code, so we get the fallback.

      expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).and_call_original
      get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('Middleware exception in exception handler')
    end

    # -------------------------------------------------------------------------

    describe 'service implementation #before and #after' do
      it 'should get called if defined in correct order' do
        expect_any_instance_of(RSpecTestServiceStubBeforeAfterImplementation).to receive(:before).once do | ignored_rspec_mock_instance, context |
          expect(context).to be_a(Hoodoo::Services::Context)
        end

        expect_any_instance_of(RSpecTestServiceStubBeforeAfterImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context).to be_a(Hoodoo::Services::Context)
        end

        expect_any_instance_of(RSpecTestServiceStubBeforeAfterImplementation).to receive(:after).once do | ignored_rspec_mock_instance, context |
          expect(context).to be_a(Hoodoo::Services::Context)
        end

        get '/v2/rspec_test_service_before_after_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      end

      it 'should not call action if before generates errors' do
        expect_any_instance_of(RSpecTestServiceStubBeforeAfterImplementation).to receive(:before).once do | ignored_rspec_mock_instance, context |
          response.add_error( 'service_calls_a.triggered')
        end

        expect_any_instance_of(RSpecTestServiceStubBeforeAfterImplementation).not_to receive(:list)

        get '/v2/rspec_test_service_before_after_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      end
    end

    # -------------------------------------------------------------------------

    describe 'service implementation #list' do
      it 'should get called with default values' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context).to be_a(Hoodoo::Services::Context)

          session = context.session
          request = context.request
          response = context.response

          expect(session).to be_a(Hoodoo::Services::Session)
          expect(request).to be_a(Hoodoo::Services::Request)
          expect(response).to be_a(Hoodoo::Services::Response)

          expect(request.locale).to eq('en-nz')
          expect(request.uri_path_components).to be_empty
          expect(request.ident).to be_nil
          expect(request.uri_path_extension).to eq('')
          expect(request.list.offset).to eq(0)
          expect(request.list.limit).to eq(50)
          expect(request.list.sort_data).to eq({'created_at'=>'desc'})
          expect(request.list.search_data).to eq({})
          expect(request.list.filter_data).to eq({})
          expect(request.embeds).to eq([])
          expect(request.references).to eq([])
        end

        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should pass on locale correctly (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.locale).to eq('en-gb')
        end

        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
                                                  'HTTP_CONTENT_LANGUAGE' => 'EN-GB' }
        expect(last_response.status).to eq(200)
      end

      it 'should pass on locale correctly (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.locale).to eq('en-gb')
        end

        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
                                                  'HTTP_ACCEPT_LANGUAGE' => 'en-GB;q=0.8, en;q=0.7' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called on varied path forms (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list)
        get '/v2/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called on varied path forms (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list)
        get '/v2/rspec_test_service_stub.json', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      context 'without ActiveRecord' do
        before :each do
          @ar = ActiveRecord
          Object.send( :remove_const, :ActiveRecord )
        end

        after :each do
          ActiveRecord = @ar
        end

        it 'still calls the service' do
          expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list)
          get '/v2/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          expect(last_response.status).to eq(200)
        end
      end

      # We allow this odd form because if it were to be considered 'show', then
      # it'd be show with no path components and a JSON format request. That
      # makes no sense. So it drops out logically as 'list'.
      #
      it 'should get called on varied path forms (3)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list)
        get '/v2/rspec_test_service_stub/.json', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).and_call_original
        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Implementation subclasses must implement 'list'")
      end

      it 'should complain if any body data is given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub/', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?imaginary=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to limit query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.offset).to eq(0)
          expect(context.request.list.limit).to eq(42)
        end

        get '/v2/rspec_test_service_stub?limit=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should take the last limit query parameter if several are given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.offset).to eq(0)
          expect(context.request.list.limit).to eq(9)
        end

        get '/v2/rspec_test_service_stub?limit=15&limit=42&limit=9', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      def test_with_limit( limit )
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get "/v2/rspec_test_service_stub?limit=#{ limit }", nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('limit')
      end

      it 'should complain about non-numeric limit query parameter' do
        test_with_limit( 'foo' )
      end

      it 'should complain about zero limit query parameter' do
        test_with_limit( 0 )
      end

      it 'should complain about negative limit query parameter' do
        test_with_limit( -1 )
      end

      it 'should respond to offset query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.offset).to eq(42)
          expect(context.request.list.limit).to eq(50)
        end

        get '/v2/rspec_test_service_stub?offset=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should take the last offset query parameter if several are given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.offset).to eq(24)
          expect(context.request.list.limit).to eq(50)
        end

        get '/v2/rspec_test_service_stub?offset=4&offset=42&offset=24', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      def test_with_offset( offset )
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get "/v2/rspec_test_service_stub?offset=#{ offset }", nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('offset')
      end

      it 'should complain about non-numeric offset query parameter' do
        test_with_offset( 'foo' )
      end

      it 'should complain about negative offset query parameter' do
        test_with_offset( -1 )
      end

      it 'should take the last offset and last query parameter if several are given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.offset).to eq(24)
          expect(context.request.list.limit).to eq(23)
        end

        get '/v2/rspec_test_service_stub?limit=2&offset=42&limit=14&limit=23&offset=24', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to sort query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'up'})
        end

        get '/v2/rspec_test_service_stub?sort=extra', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to several sort query parameters (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'up', 'created_at'=>'desc'})
        end

        get '/v2/rspec_test_service_stub?sort=extra,created_at&direction=up,desc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to several sort query parameters (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'up', 'created_at'=>'desc'})
        end

        get '/v2/rspec_test_service_stub?sort=extra&sort=created_at&direction=up,desc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to several sort query parameters, with duplicates' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'created_at'=>'desc', 'extra'=>'up'})
        end

        get '/v2/rspec_test_service_stub?sort=extra,extra&sort=created_at&sort=extra&direction=up,desc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad sort query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?sort=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('sort')
      end

      it 'should respond to direction query parameter, with infered sort' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'created_at'=>'asc'})
        end

        get '/v2/rspec_test_service_stub?direction=asc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to direction query parameter, with explicit sort' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'down'})
        end

        get '/v2/rspec_test_service_stub?sort=extra&direction=down', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to multiple direction query parameters (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'down', 'created_at'=>'asc'})
        end

        get '/v2/rspec_test_service_stub?sort=extra,created_at&direction=down,asc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to multiple direction query parameters (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.sort_data).to eq({'extra'=>'down', 'created_at'=>'asc'})
        end

        get '/v2/rspec_test_service_stub?direction=down&sort=extra,created_at&direction=asc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      # When there's more than one sort parameter, we need a matching number
      # of sort and direction keys. Use valid sort keys and directions so we
      # know that the "platform.malformed" the test expects is actually
      # coming from the count mismatch, not because the parameters are not
      # recognised sort keys or dierctions.
      #
      it 'should complain about too many direction query parameters' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?sort=created_at&direction=desc,down', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('direction')
      end

      it 'should complain about too many sort query parameters' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?sort=created_at,extra&direction=desc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('direction')
      end

      it 'should complain about bad direction query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?sort=created_at&direction=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('direction')
      end

      it 'should respond to search query parameter (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.search_data).to eq({'foo' => 'val', 'bar' => 'more'})
        end

        get '/v2/rspec_test_service_stub?search=foo%3Dval%26bar%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to search query parameter (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.search_data).to eq({'foo' => 'val', 'bar' => 'more'})
        end

        get '/v2/rspec_test_service_stub?search=foo%3Dval&search=bar%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to search query parameter, resolving duplicates' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.search_data).to eq({'foo' => 'override', 'bar' => 'more'})
        end

        get '/v2/rspec_test_service_stub?search=foo%3Dval&search=bar%3Dmore%26foo%3Doverride', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad search query parameter (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?search=thing%3Dval%26thang%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('search: thing\\, thang')
      end

      it 'should complain about bad search query parameter (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?search=thing%3Dval&search=thang%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('search: thing\\, thang')
      end

      it 'should respond to filter query parameter (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.filter_data).to eq({'baz' => 'more', 'boo' => 'val'})
        end

        get '/v2/rspec_test_service_stub?filter=boo%3Dval%26baz%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to filter query parameter (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.filter_data).to eq({'baz' => 'more', 'boo' => 'val'})
        end

        get '/v2/rspec_test_service_stub?filter=boo%3Dval&filter=baz%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to filter query parameter, resolving duplicates' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list.filter_data).to eq({'boo' => 'override1', 'baz' => 'override2'})
        end

        get '/v2/rspec_test_service_stub?filter=boo%3Dval&filter=baz%3Dmore&filter=baz%3Doverride2%26boo%3Doverride1', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad filter query parameter (form 1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?filter=thung%3Dval%26theng%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('filter: thung\\, theng')
      end

      it 'should complain about bad search and filter query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?search=thung%3Dval&filter=theng%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('search: thung\\, filter: theng')
      end

      it 'should complain about bad filter query parameter (form 2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?filter=thung%3Dval&filter=theng%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('filter: thung\\, theng')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub?_embed=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should filter out duplicates in embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub?_embed=embs,emb,embs,embs,emb,emb,embs', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?_embed=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_embed: one\\, two')
      end

      it 'should respond to reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub?_reference=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should filter out duplicates in reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub?_reference=embs,emb,embs,embs,emb,emb,embs', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?_reference=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end

      it 'should complain about several bad query parameters' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?_reference=one,emb,two&direction=asc&sort=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('sort\\, _reference: one\\, two')
      end

    end

    # -------------------------------------------------------------------------

    describe 'service implementation #show' do
      it 'should get called with correct path data (1)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.uri_path_components).to eq(['12345'])
          expect(context.request.ident).to eq('12345')
          expect(context.request.uri_path_extension).to eq('tar.gz')
        end

        get '/v2/rspec_test_service_stub/12345.tar.gz', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called with correct path data (2)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.uri_path_components).to eq(['12345', '67890'])
          expect(context.request.ident).to eq('12345')
          expect(context.request.uri_path_extension).to eq('json')
        end

        get '/v2/rspec_test_service_stub/12345/67890.json', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called with correct path data (3)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.uri_path_components).to eq(['12345abc'])
          expect(context.request.ident).to eq('12345abc')
          expect(context.request.uri_path_extension).to eq('')
        end

        get '/v2/rspec_test_service_stub/12345abc/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).and_call_original
        get '/v2/rspec_test_service_stub/12345.tar.gz', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Implementation subclasses must implement 'show'")
      end

      it 'should complain if any body data is given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:show)
        get '/v2/rspec_test_service_stub/12345.tar.gz', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:show)
        get '/v2/rspec_test_service_stub/12345?limit=25', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:show)
        get '/v2/rspec_test_service_stub/12345?imaginary=25', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub/12345?_embed=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:show)
        get '/v2/rspec_test_service_stub/12345?_embed=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_embed: one\\, two')
      end

      it 'should respond to reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        get '/v2/rspec_test_service_stub/12345?_reference=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:show)
        get '/v2/rspec_test_service_stub/12345?_reference=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end
    end

    # -------------------------------------------------------------------------

    describe 'service implementation #create' do
      it 'should complain if the payload is missing' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('generic.malformed')
      end

      it 'should complain if the payload is invalid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub', "oiushdfoisuhdf", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('generic.malformed')
      end

      it 'should complain if the payload is too large' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub', "{\"foo\": \"#{'*' * Hoodoo::Services::Middleware::MAXIMUM_PAYLOAD_SIZE }\"}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about incorrect to-create data' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub', '{ "bar": "not-an-int" }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'].size).to eq(2)
        expect(result['errors'][0]['message']).to eq('Field `foo` is required')
        expect(result['errors'][1]['message']).to eq('Field `bar` is an invalid integer')
      end

      it 'should be happy with valid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create)
        post '/v2/rspec_test_service_stub', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should be happy with no JSON and no to-create verification' do
        old = RSpecTestServiceStubInterface.to_create
        RSpecTestServiceStubInterface.send(:to_create=, nil)
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create)
        post '/v2/rspec_test_service_stub', '{}', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
        RSpecTestServiceStubInterface.send(:to_create=, old)
      end

      it 'should pass the JSON through' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
          expect(context.request.body).to eq({'foo' => 'present', 'bar' => 42})
        end

        post '/v2/rspec_test_service_stub', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if there is irrelevant path data' do
        post '/v2/rspec_test_service_stub/12345', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once.and_call_original
        post '/v2/rspec_test_service_stub/', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Implementation subclasses must implement 'create'")
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?limit=25', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?imaginary=25', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        post '/v2/rspec_test_service_stub?_embed=embs,emb', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?_embed=one,emb,two', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_embed: one\\, two')
      end

      it 'should respond to reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        post '/v2/rspec_test_service_stub?_reference=embs,emb', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?_reference=one,emb,two', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end

      context 'with X-Deja-Vu' do
        before(:each) do
          expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
            context.response.add_error(
              'generic.invalid_duplication',
              {
                :message   => 'testing duplication',
                :reference => { :field_name => 'test_field' }
              }
            )
          end
        end

        it 'handles "yes"' do
          post '/v2/rspec_test_service_stub', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
                                                                                   'HTTP_X_DEJA_VU' => 'yes' }

          expect(last_response.status).to eq(204)
          expect(last_response.headers['X-Deja-Vu']).to eq('confirmed')
          expect(last_response.body).to be_empty
        end

        ['Yes', 'No', 'no', 'foo', 'bar', 'yes '].each do | invalid_value |
          it "ignores invalid value #{invalid_value}" do
            post '/v2/rspec_test_service_stub', '{ "foo": "present", "bar": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
                                                                                     'HTTP_X_DEJA_VU' => invalid_value }

            expect(last_response.status).to eq(422)
            expect(last_response.headers).to_not include('X-Deja-Vu')
          end
        end
      end

    end

    # -------------------------------------------------------------------------

    describe 'service implementation #update' do
      it 'should complain if the payload is missing' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/1234', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('generic.malformed')
      end

      it 'should complain if the payload is invalid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/1234', "oiushdfoisuhdf", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('generic.malformed')
      end

      it 'should complain about incorrect to-update data' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/1234', '{ "baz": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'].size).to eq(1)
        expect(result['errors'][0]['message']).to eq('Field `baz` is an invalid string')
      end

      it 'should be happy with valid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update)
        patch '/v2/rspec_test_service_stub/1234', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should be happy with no JSON and no to-update verification' do
        old = RSpecTestServiceStubInterface.to_update
        RSpecTestServiceStubInterface.send(:to_update=, nil)
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update)
        patch '/v2/rspec_test_service_stub/1234', '{}', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
        RSpecTestServiceStubInterface.send(:to_update=, old)
      end

      it 'should complain about missing path components' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq('Expected path components identifying target resource instance for this action')
      end

      it 'should get called with correct path data' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).once do | ignored_rspec_mock_instance, context |
          expect(context.request.uri_path_components).to eq(['12345'])
          expect(context.request.ident).to eq('12345')
          expect(context.request.uri_path_extension).to eq('tar.gz')
        end

        patch '/v2/rspec_test_service_stub/12345.tar.gz', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).and_call_original
        patch '/v2/rspec_test_service_stub/12345.tar.gz', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Implementation subclasses must implement 'update'")
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?limit=25', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?imaginary=25', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        patch '/v2/rspec_test_service_stub/12345?_embed=embs,emb', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?_embed=one,emb,two', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_embed: one\\, two')
      end

      it 'should respond to reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        patch '/v2/rspec_test_service_stub/12345?_reference=embs,emb', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?_reference=one,emb,two', '{ "baz": "string", "foo": 42 }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end
    end

    # -------------------------------------------------------------------------

    describe 'service implementation #delete' do
      it 'should get called with correct path data' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:delete).once do | ignored_rspec_mock_instance, context |
          expect(context.request.uri_path_components).to eq(['12345'])
          expect(context.request.ident).to eq('12345')
          expect(context.request.uri_path_extension).to eq('tar.gz')
        end

        delete '/v2/rspec_test_service_stub/12345.tar.gz', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:delete).and_call_original
        delete '/v2/rspec_test_service_stub/12345.tar.gz', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Implementation subclasses must implement 'delete'")
      end

      it 'should complain if any body data is given' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:delete)
        delete '/v2/rspec_test_service_stub/12345.tar.gz', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:delete)
        delete '/v2/rspec_test_service_stub/12345?limit=25', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:delete)
        delete '/v2/rspec_test_service_stub/12345?imaginary=25', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:delete).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        delete '/v2/rspec_test_service_stub/12345?_embed=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:delete)
        delete '/v2/rspec_test_service_stub/12345?_embed=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_embed: one\\, two')
      end

      it 'should respond to reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:delete).once do | ignored_rspec_mock_instance, context |
          expect(context.request.references).to eq(['embs', 'emb'])
        end

        delete '/v2/rspec_test_service_stub/12345?_reference=embs,emb', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:delete)
        delete '/v2/rspec_test_service_stub/12345?_reference=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end
    end
  end
end


###############################################################################
# Multiple incorrectly configured endpoints
###############################################################################


class RSpecTestBrokenServiceStub < Hoodoo::Services::Service
  comprised_of RSpecTestServiceStubInterface,
               RSpecTestMatchingServiceStubInterface # I.e. same endpoint twice
end

describe Hoodoo::Services::Middleware do
  context 'bad endpoint configuration' do

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run RSpecTestBrokenServiceStub.new
      end
    end

    it 'should cause a routing exception' do
      expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
      get '/v2/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(500)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('Multiple service endpoint matches - internal server configuration fault')
    end
  end
end


###############################################################################
# Multiple correctly configured endpoints
###############################################################################


class RSpecTestServiceV1StubImplementation < Hoodoo::Services::Implementation
end

class RSpecTestServiceV1StubInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceV1StubImplementation
    actions :list, :create, :update
  end
end

class RSpecTestServiceAltStubImplementation < Hoodoo::Services::Implementation
end

class RSpecTestServiceAltStubInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_alt_stub, RSpecTestServiceAltStubImplementation
  end
end

class RSpecTestMultipleEndpointServiceStub < Hoodoo::Services::Service
  comprised_of RSpecTestServiceStubInterface,
               RSpecTestServiceV1StubInterface,
               RSpecTestServiceAltStubInterface
end

describe Hoodoo::Services::Middleware do

  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecTestMultipleEndpointServiceStub.new
    end
  end

  context 'multiple endpoints and versions' do
    it 'should return 404 with no matching route' do
      get '/v1/nowhere/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(404)
    end

    it 'should route to the V1 endpoint' do
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to receive(:list)
      get '/v1/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end

    it 'should route to the V2 endpoint' do
      expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list)
      get '/v2/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end

    it 'should route to the V2 alternative endpoint' do
      expect_any_instance_of(RSpecTestServiceAltStubImplementation).to receive(:list)
      get '/v2/rspec_test_service_alt_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end
  end

  context 'with limited supported actions' do
    it 'should accept supported actions' do
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to receive(:list)
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to receive(:create)
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to receive(:update)

      get '/v1/rspec_test_service_stub/', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)

      post '/v1/rspec_test_service_stub/', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)

      patch '/v1/rspec_test_service_stub/1234', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end

    it 'should reject unsupported actions' do
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to_not receive(:show)
      expect_any_instance_of(RSpecTestServiceV1StubImplementation).to_not receive(:delete)

      get '/v1/rspec_test_service_stub/1234', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(405)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.method_not_allowed')
      expect(result['errors'][0]['message']).to eq("Service endpoint '/v1/rspec_test_service_stub' does not support HTTP method 'GET' yielding action 'show'")

      delete '/v1/rspec_test_service_stub/1234', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(405)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.method_not_allowed')
      expect(result['errors'][0]['message']).to eq("Service endpoint '/v1/rspec_test_service_stub' does not support HTTP method 'DELETE' yielding action 'delete'")
    end
  end
end


###############################################################################
# Custom service error descriptions
###############################################################################


class RSpecTestServiceWithErrorsStubImplementation < Hoodoo::Services::Implementation
end

class RSpecTestServiceWithErrorsStubInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    version 42
    endpoint :rspec_test_service_with_errors_stub, RSpecTestServiceWithErrorsStubImplementation
    errors_for :rspec do
      error 'hello', :status => 418, 'message' => "I'm a teapot", 'reference' => { :rfc => '2324' }
    end
  end
end

class RSpecTestServiceWithErrorsStub < Hoodoo::Services::Service
  comprised_of RSpecTestServiceWithErrorsStubInterface
end

describe Hoodoo::Services::Middleware do
  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecTestServiceWithErrorsStub.new
    end
  end

  it 'should define custom errors' do
    expect_any_instance_of(RSpecTestServiceWithErrorsStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
      expect(context.response.errors.instance_variable_get('@descriptions').describe('rspec.hello')).to eq({ 'status' => 418, 'message' => "I'm a teapot", 'reference' => { 'rfc' => '2324' } })
    end

    get '/v42/rspec_test_service_with_errors_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq(200)
  end
end
