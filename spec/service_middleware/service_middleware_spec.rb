# This unavoidably combines a lot of elements of integration testing since
# little of the middleware is really usable in isolation. We could test its
# component methods individually, but the interesting ones are all part of
# request processing anyway. Code coverage lets us know if we missed any
# internal methods when testing the request processing flow.

require 'spec_helper'

class RSpecTestServiceStubImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceStubInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_stub, RSpecTestServiceStubImplementation
    embeds :emb, :embs
    to_list do
      sort :extra => [:up, :down]
      search :foo, :bar
      filter :baz, :boo
    end
  end
end

class RSpecTestServiceStub < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceStubInterface
end

describe ApiTools::ServiceMiddleware do

  def app
    Rack::Builder.new do
      use ApiTools::ServiceMiddleware
      run RSpecTestServiceStub.new
    end
  end

  context 'internal sanity checks' do
    it 'should complain about bad instantiation' do
      expect {
        ApiTools::ServiceMiddleware.new( {} )
      }.to raise_error(RuntimeError, "ApiTools::ServiceMiddleware instance created with non-ServiceApplication entity of class 'Hash' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?")
    end

    it 'should complain about bad applications' do
      class RSpecTestServiceStubBadInterface < ApiTools::ServiceInterface
      end
      class RSpecTestServiceStubBad < ApiTools::ServiceApplication
        comprised_of RSpecTestServiceStubBadInterface
      end

      expect {
        ApiTools::ServiceMiddleware.new( RSpecTestServiceStubBad.new )
      }.to raise_error(RuntimeError, "ApiTools::ServiceMiddleware encountered invalid interface class RSpecTestServiceStubBadInterface via service class RSpecTestServiceStubBad")
    end

    it 'should self-check content type' do
      mw = ApiTools::ServiceMiddleware.new( RSpecTestServiceStub.new )
      mw.instance_variable_set( '@content_type', 'application/xml' )
      mw.instance_variable_set( '@response', ApiTools::ServiceResponse.new )
      expect {
        mw.send( :payload_to_hash, '{}' )
      }.to raise_error(RuntimeError, "Internal error - content type 'application/xml' is not supported here; \#check_content_type_header() should have caught that");
    end
  end

  context 'malformed basics in requests' do

    it 'should complain about entirely missing content type' do
      get '/v2/rspec_test_service_stub'

      expect(last_response.status).to eq(422)

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
      expect(result['errors'][0]['message']).to eq("Content-Type '' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'")
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

  #############################################################################

  context 'well formed request for' do

    it 'no matching endpoint should return 404 with lower case in content type' do
      get '/v2/where_are_you', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(404)
    end

    it 'no matching endpoint should return 404 with mixed case in content type' do
      get '/v2/where_are_you', nil, { 'CONTENT_TYPE' => 'APPLICATION/json; charset=UTF-8' }
      expect(last_response.status).to eq(404)
    end

    it 'a matching endpoint should use fallback exception handler if the primary handler fails' do
      # We break the "::environment" class method so that it raises an error.
      # This is used during normal exception handling to determine whether or
      # not a backtrace should be encoded in the JSON response. By raising an
      # exception here, we test the fallback exception handler.

      expect(ApiTools::ServiceMiddleware).to receive(:environment).and_raise("boo!")

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

    describe 'service implementation #list' do
      it 'should get called with default values' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context).to be_a(ApiTools::ServiceContext)

          session = context.session
          request = context.request
          response = context.response

          expect(session).to be_a(ApiTools::ServiceSession)
          expect(request).to be_a(ApiTools::ServiceRequest)
          expect(response).to be_a(ApiTools::ServiceResponse)

          expect(request.rack_request).to be_a(Rack::Request)
          expect(request.uri_path_components).to be_empty
          expect(request.uri_path_extension).to eq('')
          expect(request.list_offset).to eq(0)
          expect(request.list_limit).to eq(50)
          expect(request.list_sort_key).to eq('created_at')
          expect(request.list_sort_direction).to eq('desc')
          expect(request.list_search_data).to be_nil
          expect(request.list_filter_data).to be_nil
          expect(request.embeds).to be_nil
          expect(request.references).to be_nil
        end

        get '/v2/rspec_test_service_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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
        expect(result['errors'][0]['message']).to eq("ApiTools::ServiceImplementation subclasses must implement 'list'")
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
          expect(context.request.list_offset).to eq(0)
          expect(context.request.list_limit).to eq(42)
        end

        get '/v2/rspec_test_service_stub?limit=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad limit query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?limit=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('limit')
      end

      it 'should respond to offset query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_offset).to eq(42)
          expect(context.request.list_limit).to eq(50)
        end

        get '/v2/rspec_test_service_stub?offset=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad offset query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?offset=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('offset')
      end

      it 'should respond to sort query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_sort_key).to eq('extra')
          expect(context.request.list_sort_direction).to eq('up')
        end

        get '/v2/rspec_test_service_stub?sort=extra', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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

      it 'should respond to direction query parameter (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_sort_key).to eq('created_at')
          expect(context.request.list_sort_direction).to eq('asc')
        end

        get '/v2/rspec_test_service_stub?direction=asc', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should respond to direction query parameter (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_sort_key).to eq('extra')
          expect(context.request.list_sort_direction).to eq('down')
        end

        get '/v2/rspec_test_service_stub?sort=extra&direction=down', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad direction query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?direction=foo', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('direction')
      end

      it 'should respond to search query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_search_data).to eq({'foo' => 'val', 'bar' => 'more'})
        end

        get '/v2/rspec_test_service_stub?search=foo%3Dval%26bar%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad search query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?search=thing%3Dval%26thang%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('search: thing\\, thang')
      end

      it 'should respond to filter query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
          expect(context.request.list_filter_data).to eq({'baz' => 'more', 'boo' => 'val'})
        end

        get '/v2/rspec_test_service_stub?filter=boo%3Dval%26baz%3Dmore', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad filter query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?filter=thung%3Dval%26theng%3Dval', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:list)
        get '/v2/rspec_test_service_stub?_reference=one,emb,two', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
      end

    end

    # -------------------------------------------------------------------------

    describe 'service implementation #show' do
      it 'should get called with correct path data (1)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.rack_request).to be_a(Rack::Request)
          expect(context.request.uri_path_components).to eq(['12345'])
          expect(context.request.uri_path_extension).to eq('tar.gz')
        end

        get '/v2/rspec_test_service_stub/12345.tar.gz', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called with correct path data (2)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.rack_request).to be_a(Rack::Request)
          expect(context.request.uri_path_components).to eq(['12345', '67890'])
          expect(context.request.uri_path_extension).to eq('json')
        end

        get '/v2/rspec_test_service_stub/12345/67890.json', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called with correct path data (3)' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:show).once do | ignored_rspec_mock_instance, context |
          expect(context.request.rack_request).to be_a(Rack::Request)
          expect(context.request.uri_path_components).to eq(['12345abc'])
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
        expect(result['errors'][0]['message']).to eq("ApiTools::ServiceImplementation subclasses must implement 'show'")
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
        post '/v2/rspec_test_service_stub', "{\"foo\": \"#{'*' * ApiTools::ServiceMiddleware::MAXIMUM_PAYLOAD_SIZE }\"}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should be happy with valid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create)
        post '/v2/rspec_test_service_stub', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should pass the JSON through' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
          expect(context.request.body).to eq({'one' => 'two'})
        end

        post '/v2/rspec_test_service_stub', '{"one": "two"}', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if there is irrelevant path data' do
        post '/v2/rspec_test_service_stub/12345', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once.and_call_original
        post '/v2/rspec_test_service_stub/', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("ApiTools::ServiceImplementation subclasses must implement 'create'")
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?limit=25', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?imaginary=25', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:create).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        post '/v2/rspec_test_service_stub?_embed=embs,emb', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?_embed=one,emb,two', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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

        post '/v2/rspec_test_service_stub?_reference=embs,emb', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:create)
        post '/v2/rspec_test_service_stub?_reference=one,emb,two', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
        expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
        expect(result['errors'][0]['reference']).to eq('_reference: one\\, two')
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

      it 'should be happy with valid JSON' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update)
        patch '/v2/rspec_test_service_stub/1234', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should get called with correct path data' do

        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).once do | ignored_rspec_mock_instance, context |
          expect(context.request.rack_request).to be_a(Rack::Request)
          expect(context.request.uri_path_components).to eq(['12345'])
          expect(context.request.uri_path_extension).to eq('tar.gz')
        end

        patch '/v2/rspec_test_service_stub/12345.tar.gz', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain if the subclass omits the implementation' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).and_call_original
        patch '/v2/rspec_test_service_stub/12345.tar.gz', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(500)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['message']).to eq("ApiTools::ServiceImplementation subclasses must implement 'update'")
      end

      it 'should complain about prohibited query entries (1)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?limit=25', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should complain about prohibited query entries (2)' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?imaginary=25', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(422)
        result = JSON.parse(last_response.body)
        expect(result['errors'][0]['code']).to eq('platform.malformed')
      end

      it 'should respond to embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to receive(:update).once do | ignored_rspec_mock_instance, context |
          expect(context.request.embeds).to eq(['embs', 'emb'])
        end

        patch '/v2/rspec_test_service_stub/12345?_embed=embs,emb', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad embed query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?_embed=one,emb,two', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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

        patch '/v2/rspec_test_service_stub/12345?_reference=embs,emb', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq(200)
      end

      it 'should complain about bad reference query parameter' do
        expect_any_instance_of(RSpecTestServiceStubImplementation).to_not receive(:update)
        patch '/v2/rspec_test_service_stub/12345?_reference=one,emb,two', "{}", { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
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
          expect(context.request.rack_request).to be_a(Rack::Request)
          expect(context.request.uri_path_components).to eq(['12345'])
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
        expect(result['errors'][0]['message']).to eq("ApiTools::ServiceImplementation subclasses must implement 'delete'")
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

class RSpecTestBrokenServiceStub < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceStubInterface,
               RSpecTestServiceStubInterface # I.e. same endpoint twice, whether via the same interface class as here, or via a different class that routed the same way - doesn't matter
end

describe ApiTools::ServiceMiddleware do
  context 'bad endpoint configuration' do

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
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

class RSpecTestServiceV1StubImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceV1StubInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceV1StubImplementation
    actions :list, :create, :update
  end
end

class RSpecTestServiceAltStubImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceAltStubInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    version 2
    endpoint :rspec_test_service_alt_stub, RSpecTestServiceAltStubImplementation
  end
end

class RSpecTestMultipleEndpointServiceStub < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceStubInterface,
               RSpecTestServiceV1StubInterface,
               RSpecTestServiceAltStubInterface
end

describe ApiTools::ServiceMiddleware do

  def app
    Rack::Builder.new do
      use ApiTools::ServiceMiddleware
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
      expect(last_response.status).to eq(422)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.method_not_allowed')
      expect(result['errors'][0]['message']).to eq("Service endpoint '/v1/rspec_test_service_stub' does not support HTTP method 'GET' yielding action 'show'")

      delete '/v1/rspec_test_service_stub/1234', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(422)
      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.method_not_allowed')
      expect(result['errors'][0]['message']).to eq("Service endpoint '/v1/rspec_test_service_stub' does not support HTTP method 'DELETE' yielding action 'delete'")
    end
  end
end

class RSpecTestServiceWithErrorsStubImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceWithErrorsStubInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    version 42
    endpoint :rspec_test_service_with_errors_stub, RSpecTestServiceWithErrorsStubImplementation
    errors_for :rspec do
      error 'hello', :status => 418, :message => "I'm a teapot", :reference => { :rfc => '2324' }
    end
  end
end

class RSpecTestServiceWithErrorsStub < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceWithErrorsStubInterface
end

describe ApiTools::ServiceMiddleware do

  def app
    Rack::Builder.new do
      use ApiTools::ServiceMiddleware
      run RSpecTestServiceWithErrorsStub.new
    end
  end

  it 'should define custom errors' do
    expect_any_instance_of(RSpecTestServiceWithErrorsStubImplementation).to receive(:list).once do | ignored_rspec_mock_instance, context |
      expect(context.response.errors.instance_variable_get('@descriptions').describe('rspec.hello')).to eq({ :status => 418, :message => "I'm a teapot", :reference => { :rfc => '2324' } })
    end

    get '/v42/rspec_test_service_with_errors_stub', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq(200)
  end
end
