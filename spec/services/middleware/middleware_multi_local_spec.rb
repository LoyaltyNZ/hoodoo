###############################################################################
# Local inter-resource local calls
###############################################################################

require 'spec_helper'

# Used for X-Assume-Identity-Of testing to avoid magic value copy-and-paste.
#
VALID_ASSUMED_IDENTITY_HASH ||= { 'caller_id' => 'custom_caller_id' }

# This gets inter-resource called from ...BImplementation. It expects search
# data containing an 'offset' key and string/integer value. If > 0, an error
# is triggered quoting the offset value in the reference data; else a hook
# method is called that we can check with RSpec.
#
# It contains one public action, to test public-to-public calling from ...B.
#
class RSpecTestInterResourceCallsAImplementation < Hoodoo::Services::Implementation

  def list( context )
    search_offset = ( ( context.request.list.search_data || {} )[ 'offset' ] || '0' ).to_i

    if search_offset > 0
      context.response.add_error( 'service_calls_a.triggered', 'reference' => { :offset => search_offset } )
    else
      array = [ 1, 2, 3, 4 ]
      context.response.set_estimated_resources( array, 1234 )
      context.response.set_resources( array, 4321 )
      expectable_hook( context )
    end
  end

  def show( context )
    expectable_hook( context )

    if context.request.ident == 'hello_return_error'
      context.response.add_error(
        'generic.invalid_string',
        :message => 'Returning error as requested',
        :reference => { :another => 'no other ident', :field_name => 'no ident' }
      )
    elsif context.request.ident == 'hello_return_identity' || context.request.ident == 'hello_set_good_inter_resource_identity'
      context.response.set_resource( { 'identity' => context.session.identity.to_h } )
    else
      context.response.set_resource( { 'inner' => 'shown' } )
    end
  end

  def create( context )
    expectable_hook( context )

    # If called with deja-vu requested, then to test that inter-resource
    # local calls deal with 422-style responses properly return a simulation
    # of an actual duplication. The error we add here should _not_ lead to an
    # error to the caller as Hoodoo should turn it into a 422.
    #
    if ( context.request.deja_vu )
      context.response.add_error( 'generic.invalid_duplication', :reference => { :field_name => 'deja' } )
    end

    # This tests an invalid response type from a service during a local
    # inter-resource call.
    #
    if context.request.body[ 'foo' ] == 'broken_response'
      context.response.body = self
    else
      context.response.body = { 'inner' => 'created' }
    end
  end

  def update( context )
    expectable_hook( context )
    context.response.add_header( 'X-Example-Header', 'example' )
    context.response.body = { 'inner' => 'updated' }
  end

  def delete( context )
    expectable_hook( context )
    context.response.body = { 'inner' => 'deleted' }
  end

  # ...So we can expect any instance of this class to receive this message and
  # check on the data it was given.
  #
  def expectable_hook( context )
  end
end

class RSpecTestInterResourceCallsAInterface < Hoodoo::Services::Interface
  interface :RSpecTestInterResourceCallsAResource do
    endpoint :rspec_test_inter_resource_calls_a, RSpecTestInterResourceCallsAImplementation
    public_actions :delete

    embeds :foo, :bar

    to_list do
      search :offset, :limit
      sort :extra => [ :up, :down ]
    end

    # Most of the to-create/to-update options are tested already; just use this
    # small bit of interface definition to make sure that inter-resource local
    # calls get the validation performed correctly on the "inner" service.

    to_create do
      text :foo, :required => true
    end

    errors_for 'service_calls_a' do
      error 'triggered', :status => 412, 'message' => 'Error Triggered'
    end
  end
end

# This calls ...AImplementation. Its interface contains two public actions,
# one calling through to a public action in ...AInterface, checking that a
# public action calling to another public action is successful; the other
# calls a secure method in ...AInterface and is used to make sure that a
# public action calling to a secure action is handled correctly (i.e. overall
# response is 401).
#
# Note intentional mix of 'body= ', 'set_resource' and 'set_resources' just
# to make sure those all get some coverage again.
#
class RSpecTestInterResourceCallsBImplementation < Hoodoo::Services::Implementation
  def list( context )
    expectable_hook( context )

    # Call RSpecTestInterResourceCallsAImplementation#list, with a query string
    # that 'searches' for offset and limit quantities that we get from the
    # inbound request. The sort parameter tests non-Array sorting, with the
    # direction parameter testing Array-based sorting.

    qd = {
      :sort => 'extra',
      :direction => [ 'down' ],
      :search => {
        :offset => context.request.list.offset,
        :limit  => context.request.list.limit
      },
      :_embed => [ 'foo' ]
    }

    # Set limit to 10 to force an invalid search parameter which should cause
    # a 422 in A, which B merges and returns.

    if (context.request.list.limit.to_s == '10')
      qd[:search][:foo] = 'bar'
    end

    result = context.resource( :RSpecTestInterResourceCallsAResource ).list(qd)
    result.adds_errors_to?( context.response.errors )
    expectable_result_hook( result )
    context.response.set_resources( [ { :result => result, :options => result.response_options } ] )
  end

  def show( context )
    expectable_hook( context )

    if context.request.ident == 'call_c'
      result = context.resource( :RSpecTestInterResourceCallsCResource ).show(
        context.request.ident,
        {}
      )
    else
      resource = context.resource( :RSpecTestInterResourceCallsAResource )

      if ( context.request.ident == 'set_bad_inter_resource_identity' )
        resource.assume_identity_of = {
          VALID_ASSUMED_IDENTITY_HASH.keys.first => Hoodoo::UUID.generate
        }
      elsif ( context.request.ident == 'set_good_inter_resource_identity' )
        resource.assume_identity_of = VALID_ASSUMED_IDENTITY_HASH
      end

      result = resource.show(
        'hello_' + context.request.ident,
        { :_embed => :foo }
      )
    end

    expectable_result_hook( result )

    context.response.add_errors( result.platform_errors )
    context.response.body = { :result => result, :options => result.response_options }
  end

  def create( context )
    expectable_hook( context )

    endpoint = context.resource( :RSpecTestInterResourceCallsAResource )

    # This implementation makes an inter-resource call which just passes
    # on the caller's provided body data. If someone used X-Resource-UUID
    # in their top-level call with permission, 'body' will contain 'id'
    # and that'll be rejected if we pass it through an inter-resource call
    # (you must use the high-level interface to do that), assuming things
    # are working properly and the X-Resource-UUID specification is *not*
    # automatically inherited to inter-resource endpoints.
    #
    # This is for *top level* calls specifying UUIDs to *this resource*.
    #
    context.request.body.delete( 'id' )

    if context.request.body[ 'foo' ] == 'specify_uuid'

      # If given the magic string "specify_uuid" in the mandatory resource
      # text field "foo", then specifically make an inter-resource call with
      # a resource UUID specified for the inner resource. This checks the
      # permissions handling on "internal" inter-resource calls.
      #
      # This is for *inter-resource* calls *from* this resource to the target
      # resource and has nothing to do with anything the top-level API caller
      # specified.
      #
      endpoint.resource_uuid = Hoodoo::UUID.generate()

    elsif context.request.body[ 'foo' ] == 'deja_vu'

      # This tests an inter-resource call specifying deja-vu and dealing with
      # responses.
      #
      endpoint.deja_vu = true

    end

    result = endpoint.create(
      context.request.body,
      { :_embed => 'foo' }
    )

    expectable_result_hook( result )

    # There are two tests hidden here. Note that if there's an error,
    # we're actually not setting response body, leaving it 'nil'; make
    # sure nothing barfs on that.
    #
    if result.adds_errors_to?( context.response.errors )
      expectable_result_failure_hook( result )
    else
      if result.empty?
        context.response.set_resource( { :result     => 'I experienced deja-vu',
                                         :options    => result.response_options } )
      else
        context.response.set_resource( { :result     => result,
                                         :options    => result.response_options,
                                         :dated_from => context.request.dated_from } )
      end
    end
  end

  def update( context )
    expectable_hook( context )
    result = context.resource( :RSpecTestInterResourceCallsAResource ).update(
      'hello_' + context.request.ident,
      context.request.body,
      { :_embed => 'foo' }
    )
    expectable_result_hook( result )
    context.response.add_errors( result.platform_errors )
    context.response.body = { :result => result, :options => result.response_options }
  end

  def delete( context )
    return context.response.not_found( context.request.ident ) if ( context.request.ident == 'simulate_404' )

    expectable_hook( context )
    result = context.resource( :RSpecTestInterResourceCallsAResource ).delete(
      'hello_' + context.request.ident,
      { :_embed => [ :foo ] }
    )
    expectable_result_hook( result )
    context.response.add_errors( result.platform_errors )
    context.response.body = { :result => result, :options => result.response_options }
  end

  # ...So we can expect any instance of this class to receive these messages
  # and check on the data it was given or is returning.
  #
  def expectable_hook( context )
  end
  def expectable_result_hook( result )
  end
  def expectable_result_failure_hook( result )
  end
end

class RSpecTestInterResourceCallsBInterface < Hoodoo::Services::Interface
  interface :RSpecTestInterResourceCallsBResource do
    endpoint :rspec_test_inter_resource_calls_b, RSpecTestInterResourceCallsBImplementation
    public_actions :update, :delete
  end
end

class RSpecTestInterResourceCallsCImplementation < Hoodoo::Services::Implementation

  # This gets inter-resource called from ...BImplementation too. It only implements
  # one action so is used for action validation tests.

  def list( context )
    context.response.body = [ 1,2,3,4 ]
  end
end

class RSpecTestInterResourceCallsCInterface < Hoodoo::Services::Interface
  interface :RSpecTestInterResourceCallsCResource do
    endpoint :rspec_test_inter_resource_calls_c, RSpecTestInterResourceCallsCImplementation
    actions :list
  end
end

class RSpecTestInterResourceCalls < Hoodoo::Services::Service
  comprised_of RSpecTestInterResourceCallsAInterface,
               RSpecTestInterResourceCallsBInterface,
               RSpecTestInterResourceCallsCInterface
end

describe Hoodoo::Services::Middleware::InterResourceLocal do

  before :each do
    @test_uuid = Hoodoo::UUID.generate()
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    @test_session = @old_test_session.dup
    permissions = Hoodoo::Services::Permissions.new # (this is "default-else-deny")
    permissions.set_default_fallback( Hoodoo::Services::Permissions::ALLOW )
    @test_session.permissions = permissions
    @test_session.scoping.authorised_http_headers = [] # (no secured headers allowed to start with)
    Hoodoo::Services::Middleware.set_test_session( @test_session )
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

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
      run RSpecTestInterResourceCalls.new
    end
  end

  before :each do
    @interaction_id = Hoodoo::UUID.generate()
  end

  before :example, :check_callbacks => true do
    expect_any_instance_of( RSpecTestInterResourceCallsBImplementation ).to receive( :before ).once
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:before ).once
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:after ).once
    # <- B
    expect_any_instance_of( RSpecTestInterResourceCallsBImplementation ).to receive( :after ).once
  end

  def headers_for( locale:        nil,
                   dated_at:      nil,
                   dated_from:    nil,
                   deja_vu:       nil,
                   resource_uuid: nil )

    headers = {
      'HTTP_X_INTERACTION_ID' => @interaction_id,
      'CONTENT_TYPE'          => 'application/json; charset=utf-8'
    }

    headers[ 'HTTP_CONTENT_LANGUAGE' ] = locale unless locale.nil?
    headers[ 'HTTP_ACCEPT_LANGUAGE'  ] = locale unless locale.nil?
    headers[ 'HTTP_X_RESOURCE_UUID'  ] = resource_uuid unless resource_uuid.nil?
    headers[ 'HTTP_X_DATED_AT'       ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?
    headers[ 'HTTP_X_DATED_FROM'     ] = Hoodoo::Utilities.nanosecond_iso8601( dated_from ) unless dated_from.nil?
    headers[ 'HTTP_X_DEJA_VU'        ] = 'yes' if deja_vu == true

    return headers
  end

  def expect_response_options_for( options )
    expect( options ).to_not be_nil
    expect( options[ 'service_response_time' ] ).to_not be_nil
    expect( options[ 'interaction_id'        ] ).to_not be_nil
    expect( Hoodoo::UUID.valid?( options[ 'interaction_id' ] ) ).to eq( true )
  end

  def list_things(locale: nil, dated_at: nil)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:list).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.dated_at).to eq(dated_at) # Is used
      expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
      expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
      expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:list).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.owning_interaction.interaction_id).to eq(@interaction_id)
        expect(context.request.body).to be_nil
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq([])
        expect(context.request.uri_path_extension).to eq('')
        expect(context.request.list.offset).to eq(0)
        expect(context.request.list.limit).to eq(50)
        expect(context.request.list.sort_data).to eq({'extra'=>'down'})
        expect(context.request.locale).to eq(locale || 'en-nz')
        expect(context.request.dated_at).to eq(dated_at) # Is passed through inter-resource calls
        expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
        expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
        expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq([1,2,3,4])
      expect(result.dataset_size).to eq(4321)
      expect(result.estimated_dataset_size).to eq(1234)
    end

    get '/v1/rspec_test_inter_resource_calls_b',
        nil,
        headers_for(locale: locale, dated_at: dated_at)

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)

    expect(result['_data']).to_not be_nil
    expect(result['_data'][0]).to_not be_nil
    expect(result['_data'][0]['result']).to eq([1,2,3,4])
    expect_response_options_for(result['_data'][0]['options'])
  end

  it 'manages ActiveRecord when implementation is called in its presence' do
    pool = ActiveRecord::Base.connection_pool

    expect( ActiveRecord::Base ).to receive( :connection_pool ).twice.and_call_original
    expect( pool               ).to receive( :with_connection ).twice.and_call_original

    list_things()
  end

  # X-Dated-From is tested for POST elsewhere and X-Dated-At for GET
  # is tested here.
  #
  context 'when dated_at is an invalid datetime' do
    datetimes = [
                  "2015-01-01T01:00:00+0100",
                  "2015-01-01T01:00:00-0100",
                  "2015-01T01:00:00+01:00",
                  "2015-001-01T01:00:00-32:00",
                  "2015-01T01:00:00-2900",
                  "2015-01-01",
                  "not-a-date"
                ]

    datetimes.each do |datetime|
      it "complains about a bad X-Dated-At header of #{datetime}" do
        headers = headers_for(locale: 'en-nz', dated_at: DateTime.now)
        headers['HTTP_X_DATED_AT'] = datetime

        get '/v1/rspec_test_inter_resource_calls_b',
            nil,
            headers

        expect(last_response.status).to eq(422)

        result = JSON.parse(last_response.body)

        expect(result['errors'][0]['code']).to eq('generic.malformed')
        expect(result['errors'][0]['message']).to eq("X-Dated-At header value '#{ datetime }' is invalid")
        expect(result['errors'][0]['reference']).to eq("X-Dated-At")
      end
    end
  end

  it 'lists things with callbacks', :check_callbacks => true do
    list_things()
  end

  it 'lists things without callbacks' do
    list_things()
  end

  it 'lists things with a custom locale and dated_at time' do
    list_things(locale: 'foo', dated_at: DateTime.now)
  end

  it 'should report middleware level errors from the secondary service' do
    get '/v1/rspec_test_inter_resource_calls_b?limit=10', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

    expect(last_response.status).to eq(422)

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.malformed')
    expect(result['errors'][0]['message']).to eq('One or more malformed or invalid query string parameters')
    expect(result['errors'][0]['reference']).to eq('search: foo')
  end

  it 'should report custom errors from the secondary service' do
    get '/v1/rspec_test_inter_resource_calls_b?offset=42', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

    expect(last_response.status).to eq(412)

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('service_calls_a.triggered')
    expect(result['errors'][0]['reference']).to eq('42')
  end

  it 'handles incorrect return types from the "inner" service' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:list) do | instance, context |
      context.response.body = {}
    end

    get '/v1/rspec_test_inter_resource_calls_b', nil, headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.fault')
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'Hash' received from a local inter-resource call for action 'list'")
  end

  it 'gets the correct type back when an inter-resource local call generates an error' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:list) do | instance, context |
      context.response.add_error( 'platform.malformed' )
    end

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook) do | instance, result |
      expect(result).to be_a(Hoodoo::Client::AugmentedArray)
      expect(result.platform_errors.has_errors?).to eq(true)
    end

    get '/v1/rspec_test_inter_resource_calls_b', nil, headers_for()

    result = JSON.parse(last_response.body)
    expect(result['errors'][0]['code']).to eq('platform.malformed')
  end

  def show_things(locale: nil, dated_at: nil)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:show).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.dated_at).to eq(dated_at) # Is used
      expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
      expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
      expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:show).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.owning_interaction.interaction_id).to eq(@interaction_id)
        expect(context.request.body).to be_nil
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq(['hello_world'])
        expect(context.request.ident).to eq('hello_world')
        expect(context.request.uri_path_extension).to eq('')
        expect(context.request.list.offset).to eq(0)
        expect(context.request.list.limit).to eq(50)
        expect(context.request.locale).to eq(locale || 'en-nz')
        expect(context.request.dated_at).to eq(dated_at) # Is passed through inter-resource calls
        expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
        expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
        expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq({ 'inner' => 'shown' })
    end

    get '/v1/rspec_test_inter_resource_calls_b/world',
        nil,
        headers_for(locale: locale, dated_at: dated_at)

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])

    expect(result['result']).to eq({'inner' => 'shown'})
  end

  it 'shows things with callbacks', :check_callbacks => true do
    show_things()
  end

  it 'shows things without callbacks' do
    show_things()
  end

  it 'shows things with a custom locale and dated_at time' do
    show_things(locale: 'bar', dated_at: DateTime.now)
  end

  it 'handles incorrect return types from the "inner" service' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:show) do | instance, context |
      context.response.body = []
    end

    get '/v1/rspec_test_inter_resource_calls_b/world', nil, headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.fault')
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'Array' received from a local inter-resource call for action 'show'")
  end

  it 'gets the correct type back when an inter-resource local call generates an error' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:show) do | instance, context |
      context.response.add_error( 'platform.malformed' )
    end

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook) do | instance, result |
      expect(result).to be_a(Hoodoo::Client::AugmentedHash)
      expect(result.platform_errors.has_errors?).to eq(true)
    end

    get '/v1/rspec_test_inter_resource_calls_b/world', nil, headers_for()

    result = JSON.parse(last_response.body)
    expect(result['errors'][0]['code']).to eq('platform.malformed')
  end

  def create_things(locale: nil, dated_from: nil, deja_vu: nil, resource_uuid: nil)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:create).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.dated_at).to eq(nil)                # Not used => expect 'nil'
      expect(context.request.dated_from).to eq(dated_from)       # Is used
      expect(context.request.deja_vu).to eq(deja_vu)             # Is used
      expect(context.request.resource_uuid).to eq(resource_uuid) # Is used
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:create).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.owning_interaction.interaction_id).to eq(@interaction_id)
        expect(context.request.body).to eq({'foo' => 'required'})
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq([])
        expect(context.request.ident).to be_nil
        expect(context.request.locale).to eq(locale || 'en-nz')
        expect(context.request.dated_at).to eq(nil)          # Not used => expect 'nil'
        expect(context.request.dated_from).to eq(dated_from) # Is passed through inter-resource calls
        expect(context.request.deja_vu).to eq(nil)           # Is not passed through inter-resource calls
        expect(context.request.resource_uuid).to eq(nil)     # Is not passed through inter-resource calls
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq({ 'inner' => 'created' })
    end

    post '/v1/rspec_test_inter_resource_calls_b/',
         '{"foo": "required"}',
         headers_for(locale: locale, dated_from: dated_from, deja_vu: deja_vu, resource_uuid: resource_uuid)

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])

    expect(result['result']).to eq({'inner' => 'created'})
    expect(result).to have_key('dated_from')
    expect(result['dated_from']).to eq(dated_from.nil? ? nil : dated_from.to_s)
  end

  def fail_to_create_things
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:create).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to_not receive(:create)
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to_not receive(:expectable_hook)
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_failure_hook)

    post '/v1/rspec_test_inter_resource_calls_b/', '{"sum": 7}', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

    expect(last_response.status).to eq(422)

    result = JSON.parse(last_response.body)

    expect(result['errors'].size).to eq(1)
    expect(result['errors'][0]['message']).to eq('Field `foo` is required')
  end

  # X-Dated-At is tested for GET elsewhere and X-Dated-From for POST
  # is tested here.
  #
  context 'when dated_from is an invalid datetime' do
    datetimes = [
                  "2015-01-01T01:00:00+0100",
                  "2015-01-01T01:00:00-0100",
                  "2015-01T01:00:00+01:00",
                  "2015-001-01T01:00:00-32:00",
                  "2015-01T01:00:00-2900",
                  "2015-01-01",
                  "not-a-date"
                ]

    datetimes.each do |datetime|
      it "complains about a bad X-Dated-At header of #{datetime}" do
        headers = headers_for(locale: 'en-nz', dated_at: DateTime.now)
        headers['HTTP_X_DATED_FROM'] = datetime

        post '/v1/rspec_test_inter_resource_calls_b',
             '{"foo": "required"}',
             headers

        expect(last_response.status).to eq(422)

        result = JSON.parse(last_response.body)

        expect(result['errors'][0]['code']).to eq('generic.malformed')
        expect(result['errors'][0]['message']).to eq("X-Dated-From header value '#{ datetime }' is invalid")
        expect(result['errors'][0]['reference']).to eq("X-Dated-From")
      end
    end
  end

  it 'creates things with callbacks', :check_callbacks => true do
    create_things()
  end

  it 'creates things without callbacks' do
    create_things()
  end

  it 'creates things with a custom locale and passes through dated_from' do
    create_things(locale: 'baz', dated_from: DateTime.now)
  end

  it 'creates things and does not pass through deja_vu' do
    create_things(deja_vu: true)
  end

  it 'refuses to create things when the inner service gets invalid data, with callbacks' do
    expect_any_instance_of( RSpecTestInterResourceCallsBImplementation ).to receive( :before ).once
    # -> A
      expect_any_instance_of( RSpecTestInterResourceCallsAImplementation ).to_not receive( :before )
      expect_any_instance_of( RSpecTestInterResourceCallsAImplementation ).to_not receive( :after )
    # <- B
    expect_any_instance_of( RSpecTestInterResourceCallsBImplementation ).to receive( :after ).once

    fail_to_create_things()
  end

  it 'refuses to create things when the inner service gets invalid data, without callbacks' do
    fail_to_create_things()
  end

  it 'creates things with a custom UUID given permission, but does not pass it through' do
    @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]
    create_things(resource_uuid: Hoodoo::UUID.generate())
  end

  it 'fails to create things with a custom UUID if not given permission' do
    post '/v1/rspec_test_inter_resource_calls_b/',
         '{"foo": "required"}',
         headers_for(resource_uuid: Hoodoo::UUID.generate())

    expect(last_response.status).to eq(403)

    result = JSON.parse(last_response.body)

    expect(result['errors'].size).to eq(1)
    expect(result['errors'][0]['code']).to eq('platform.forbidden')
    expect(result['errors'][0]['reference']).to be_nil # Ensure no information disclosure vulnerability
  end

  it 'can specify a UUID via an inter-resource call if it has top-level permission' do
    @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.resource_uuid).to eq(nil) # Is not specified by top-level caller
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.request.resource_uuid).to_not be_nil
        expect(Hoodoo::UUID.valid?(context.request.resource_uuid)).to eq(true)
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq({ 'inner' => 'created' })
    end

    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'specify_uuid'}),
         headers_for()

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])

    expect(result['result']).to eq({'inner' => 'created'})
    expect(result).to have_key('dated_from')
    expect(result['dated_from']).to be_nil
  end

  it 'cannot specify a UUID via an inter-resource call if it does not have top-level permission' do
    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'specify_uuid'}),
         headers_for()

    expect(last_response.status).to eq(403)

    result = JSON.parse(last_response.body)

    expect(result['errors'].size).to eq(1)
    expect(result['errors'][0]['code']).to eq('platform.forbidden')
    expect(result['errors'][0]['reference']).to be_nil # Ensure no information disclosure vulnerability
  end

  it 'creates things with the inter-resource local call asking for deja-vu and being told there are duplicates' do
    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'deja_vu'}),
         headers_for()

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])

    expect(result['result']).to eq('I experienced deja-vu')
  end

  it 'handles broken service responses' do
    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'broken_response'}),
         headers_for()

    expect(last_response.status).to eq(500)
    result = JSON.parse(last_response.body)
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'RSpecTestInterResourceCallsAImplementation' received from a local inter-resource call for action 'create'")
  end

  it 'handles incorrect return types from the "inner" service' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:create) do | instance, context |
      context.response.body = OpenStruct.new
    end

    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'bar'}),
         headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.fault')
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'OpenStruct' received from a local inter-resource call for action 'create'")
  end

  it 'gets the correct type back when an inter-resource local call generates an error' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:create) do | instance, context |
      context.response.add_error( 'platform.malformed' )
    end

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook) do | instance, result |
      expect(result).to be_a(Hoodoo::Client::AugmentedHash)
      expect(result.platform_errors.has_errors?).to eq(true)
    end

    post '/v1/rspec_test_inter_resource_calls_b/',
         JSON.fast_generate({:foo => 'bar'}),
         headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.malformed')
  end

  def update_things(locale: nil)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:update).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.dated_at).to eq(nil)      # Not used => expect 'nil'
      expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
      expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
      expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:update).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.owning_interaction.interaction_id).to eq(@interaction_id)
        expect(context.request.body).to eq({'sum' => 70})
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq(['hello_world'])
        expect(context.request.ident).to eq('hello_world')
        expect(context.request.locale).to eq(locale || 'en-nz')
        expect(context.request.dated_at).to eq(nil)      # Not used => expect 'nil'
        expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
        expect(context.request.deja_vu).to eq(nil)       # Not used => expect 'nil'
        expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq({ 'inner' => 'updated' })
    end

    patch '/v1/rspec_test_inter_resource_calls_b/world',
          '{"sum": 70}',
          headers_for(locale: locale)

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])
    expect(result['options']['example_header']).to eq('example')

    expect(result['result']).to eq({'inner' => 'updated'})
  end

  it 'updates things with callbacks', :check_callbacks => true do
    update_things()
  end

  it 'updates things with a custom locale' do
    update_things(locale: 'boo')
  end

  it 'handles incorrect return types from the "inner" service' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:update) do | instance, context |
      context.response.body = "string"
    end

    patch '/v1/rspec_test_inter_resource_calls_b/world', '{}', headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.fault')
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'String' received from a local inter-resource call for action 'update'")
  end

  it 'gets the correct type back when an inter-resource local call generates an error' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:update) do | instance, context |
      context.response.add_error( 'platform.malformed' )
    end

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook) do | instance, result |
      expect(result).to be_a(Hoodoo::Client::AugmentedHash)
      expect(result.platform_errors.has_errors?).to eq(true)
    end

    patch '/v1/rspec_test_inter_resource_calls_b/world', '{}', headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.malformed')
  end

  def delete_things(locale: nil, deja_vu: nil)
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:delete).once.and_call_original
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
      expect(context.request.dated_at).to eq(nil)      # Not used => expect 'nil'
      expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
      expect(context.request.deja_vu).to eq(deja_vu)   # Is used
      expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
    end
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:delete).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.owning_interaction.interaction_id).to eq(@interaction_id)
        expect(context.request.body).to be_nil
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq(['hello_world'])
        expect(context.request.ident).to eq('hello_world')
        expect(context.request.locale).to eq(locale || 'en-nz')
        expect(context.request.dated_at).to eq(nil)      # Not used => expect 'nil'
        expect(context.request.dated_from).to eq(nil)    # Not used => expect 'nil'
        expect(context.request.deja_vu).to eq(nil)       # Is not passed through inter-resource calls
        expect(context.request.resource_uuid).to eq(nil) # Not used => expect 'nil'
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once do | ignored_rspec_mock_instance, result |
      expect(result).to eq({ 'inner' => 'deleted' })
    end

    delete '/v1/rspec_test_inter_resource_calls_b/world',
           nil,
           headers_for(locale: locale, deja_vu: deja_vu)

    expect(last_response.status).to eq(200)

    result = JSON.parse(last_response.body)
    expect_response_options_for(result['options'])

    expect(result['result']).to eq({'inner' => 'deleted'})
  end

  it 'deletes things with callbacks', :check_callbacks => true do
    delete_things()
  end

  it 'deletes things without callbacks' do
    delete_things()
  end

  it 'deletes things with a custom locale' do
    delete_things(locale: 'bye')
  end

  it 'deletes things and passes through deja_vu' do
    delete_things(deja_vu: true)
  end

  it 'deletes things with a simulated 404' do
    delete '/v1/rspec_test_inter_resource_calls_b/simulate_404',
           nil,
           headers_for()

    expect(last_response.status).to eq(404)
    result = JSON.parse(last_response.body)
    expect(result['errors'][0]['code']).to eq('generic.not_found')
  end

  it 'deletes things with a 204 with deja vu' do
    delete '/v1/rspec_test_inter_resource_calls_b/simulate_404',
           nil,
           headers_for(deja_vu: true)

    expect(last_response.status).to eq(204)
    expect(last_response.body).to be_empty
    expect(last_response['X-Deja-Vu']).to eq('confirmed')
  end

  it 'handles incorrect return types from the "inner" service' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:delete) do | instance, context |
      context.response.body = instance
    end

    delete '/v1/rspec_test_inter_resource_calls_b/world', nil, headers_for()

    result = JSON.parse(last_response.body)

    expect(result['errors'][0]['code']).to eq('platform.fault')
    expect(result['errors'][0]['message']).to eq("Hoodoo::Services::Middleware: Unexpected response type 'RSpecTestInterResourceCallsAImplementation' received from a local inter-resource call for action 'delete'")
  end

  it 'gets the correct type back when an inter-resource local call generates an error' do
    expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:delete) do | instance, context |
      context.response.add_error( 'platform.malformed' )
    end

    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook) do | instance, result |
      expect(result).to be_a(Hoodoo::Client::AugmentedHash)
      expect(result.platform_errors.has_errors?).to eq(true)
    end

    delete '/v1/rspec_test_inter_resource_calls_b/world', nil, headers_for()

    result = JSON.parse(last_response.body)
    expect(result['errors'][0]['code']).to eq('platform.malformed')
  end

  it 'should see errors from the inner call correctly' do
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:show).once.and_call_original
    # -> A
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:show).once.and_call_original
      expect_any_instance_of(RSpecTestInterResourceCallsAImplementation).to receive(:expectable_hook).once do | ignored_rspec_mock_instance, context |
        expect(context.request.body).to be_nil
        expect(context.request.embeds).to eq(['foo'])
        expect(context.request.uri_path_components).to eq(['hello_return_error'])
        expect(context.request.ident).to eq('hello_return_error')
        expect(context.request.uri_path_extension).to eq('')
        expect(context.request.list.offset).to eq(0)
        expect(context.request.list.limit).to eq(50)
      end
    # <- B
    expect_any_instance_of(RSpecTestInterResourceCallsBImplementation).to receive(:expectable_result_hook).once.and_call_original

    get '/v1/rspec_test_inter_resource_calls_b/return_error', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq(422)
    result = JSON.parse(last_response.body)
    expect( result[ 'errors' ] ).to_not be_nil
    expect( result[ 'errors' ][ 0 ] ).to eq({
      'code'      => 'generic.invalid_string',
      'message'   => 'Returning error as requested',
      'reference' => 'no ident,no other ident'
    })
  end

  context 'X-Assume-Identity-Of' do
    context 'top-level use permitted' do
      before :each do
        @old_test_session = Hoodoo::Services::Middleware.test_session()

        test_session          = @old_test_session.dup
        test_session.identity = test_session.identity.dup
        test_session.scoping  = test_session.scoping.dup

        test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
        test_session.scoping.authorised_identities   = {
          VALID_ASSUMED_IDENTITY_HASH.keys.first =>
          [ VALID_ASSUMED_IDENTITY_HASH.values.first ]
        }

        Hoodoo::Services::Middleware.set_test_session( test_session )
      end

      after :each do
        Hoodoo::Services::Middleware.set_test_session( @old_test_session )
      end

      context 'when in use at top level' do
        it 'sees correct identity in the downstream resource' do
          get(
            '/v1/rspec_test_inter_resource_calls_b/return_identity',
            nil,
            {
              'CONTENT_TYPE' => 'application/json; charset=utf-8',
              'HTTP_X_ASSUME_IDENTITY_OF' => URI.encode_www_form( VALID_ASSUMED_IDENTITY_HASH )
            }
          )

          result = JSON.parse( last_response.body )
          expect( result[ 'result' ][ 'identity' ] ).to eq( VALID_ASSUMED_IDENTITY_HASH )
        end

        it 'cannot set an illegal identity in the inter-resource call' do
          get(
            '/v1/rspec_test_inter_resource_calls_b/set_bad_inter_resource_identity',
            nil,
            {
              'CONTENT_TYPE' => 'application/json; charset=utf-8',
              'HTTP_X_ASSUME_IDENTITY_OF' => URI.encode_www_form( VALID_ASSUMED_IDENTITY_HASH )
            }
          )

          expect( last_response.status ).to eq( 403 )
          result = JSON.parse( last_response.body )
          expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
        end
      end

      context 'in inter-resource call only' do
        identity_hash = { 'caller_id' => 'custom_caller_id' }

        it 'can still set identity for the downstream resource' do
          get(
            '/v1/rspec_test_inter_resource_calls_b/set_good_inter_resource_identity',
            nil,
            { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          )

          result = JSON.parse( last_response.body )
          expect( result[ 'result' ][ 'identity' ] ).to eq( VALID_ASSUMED_IDENTITY_HASH )
        end

        it 'cannot set an illegal identity for the downstream resource' do
          get(
            '/v1/rspec_test_inter_resource_calls_b/set_bad_inter_resource_identity',
            nil,
            { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          )

          expect( last_response.status ).to eq( 403 )
          result = JSON.parse( last_response.body )
          expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
        end
      end
    end

    context 'top-level use prohibited' do
      before :each do
        @old_test_session = Hoodoo::Services::Middleware.test_session()

        test_session          = @old_test_session.dup
        test_session.identity = test_session.identity.dup
        test_session.scoping  = test_session.scoping.dup

        test_session.scoping.authorised_http_headers = [] # NO ALLOWED HEADERS
        test_session.scoping.authorised_identities   = { 'caller_id' => [ 'custom_caller_id' ] }

        Hoodoo::Services::Middleware.set_test_session( test_session )
      end

      after :each do
        Hoodoo::Services::Middleware.set_test_session( @old_test_session )
      end

      # middleware_assumed_identity_spec.rb already comprehensively tests
      # top-level calls, so just do the inter-resource check here.
      #
      it 'cannot override a valid identity in inter-resource calls' do
        get(
          '/v1/rspec_test_inter_resource_calls_b/set_good_inter_resource_identity',
          nil,
          { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        )

        expect( last_response.status ).to eq( 403 )
        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end
    end
  end

  it 'should get told if an action is not supported' do
    expect_any_instance_of(RSpecTestInterResourceCallsCImplementation).to_not receive(:show)
    expect_any_instance_of(RSpecTestInterResourceCallsCImplementation).to_not receive(:expectable_hook)

    get '/v1/rspec_test_inter_resource_calls_b/call_c', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq(405)
    result = JSON.parse(last_response.body)
    expect( result[ 'errors' ] ).to_not be_nil
    expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.method_not_allowed' )
  end

  context 'with no session' do
    before :example do
      @old_test_session = Hoodoo::Services::Middleware.test_session()
      Hoodoo::Services::Middleware.set_test_session( nil )
    end

    after :example do
      Hoodoo::Services::Middleware.set_test_session( @old_test_session )
    end

    it 'can call public-to-public actions successfully' do
      delete '/v1/rspec_test_inter_resource_calls_b/world', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end

    it 'cannot call the secure update method in the other service without a session' do
      patch '/v1/rspec_test_inter_resource_calls_b/world', '{"sum": 70}', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(401)
    end
  end
end
