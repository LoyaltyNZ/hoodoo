require 'spec_helper'

describe Hoodoo::Services::Response do
  before :each do
    @r = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
  end

  it 'should acquire the expected default values when instantiated' do
    expect(@r.errors).to be_a(Hoodoo::Errors)
    expect(@r.errors.has_errors?).to eq(false)
    expect(@r.http_status_code).to eq(200)
    expect(@r.body).to eq({})
    expect(@r.instance_variable_get('@headers')).to eq({})
  end

  context 'instantiation' do
    it 'rejects a nil interaction ID' do
      expect {
        Hoodoo::Services::Response.new( nil )
      }.to raise_error( RuntimeError, "Hoodoo::Services::Response.new must be given a valid Interaction ID (got 'nil')" )
    end

    it 'rejects a non-string interaction ID' do
      expect {
        Hoodoo::Services::Response.new( 12345 )
      }.to raise_error( RuntimeError, "Hoodoo::Services::Response.new must be given a valid Interaction ID (got '12345')" )
    end

    it 'rejects an invalid string interaction ID' do
      expect {
        Hoodoo::Services::Response.new( 'hello' )
      }.to raise_error( RuntimeError, "Hoodoo::Services::Response.new must be given a valid Interaction ID (got '\"hello\"')" )
    end
  end

  context '#add_error and #halt_processing?' do
    it 'should not say "halt" if there are no errors' do
      expect(@r.errors.has_errors?).to eq(false)
      expect(@r.halt_processing?).to eq(false)
    end

    it 'should say "halt" if there are errors' do
      @r.add_error('platform.malformed')
      expect(@r.errors.has_errors?).to eq(true)
      expect(@r.halt_processing?).to eq(true)
    end
  end

  context '#add_errors' do
    it 'should merge errors (1)' do
      e = Hoodoo::Errors.new
      e.add_error( 'platform.malformed' )
      e.add_error( 'generic.malformed' )

      @r.add_error( 'platform.invalid_session' )
      expect( @r.add_errors( e ) ).to eq( true )

      expect(@r.errors.errors).to eq([
        { 'code' => 'platform.invalid_session', 'message' => 'Invalid session'   },
        { 'code' => 'platform.malformed',       'message' => 'Malformed request' },
        { 'code' => 'generic.malformed',        'message' => 'Malformed payload' }
      ])

      # Should keep the HTTP status code from the first error added,
      # which was the "invalid session" we added.

      expect(@r.errors.http_status_code).to eq(401)
    end

    it 'should merge errors (2)' do
      e = Hoodoo::Errors.new
      e.add_error( 'platform.malformed' )
      e.add_error( 'generic.malformed' )

      expect( @r.add_errors( e ) ).to eq( true )
      @r.add_error( 'platform.invalid_session' )

      expect(@r.errors.errors).to eq([
        { 'code' => 'platform.malformed',       'message' => 'Malformed request' },
        { 'code' => 'generic.malformed',        'message' => 'Malformed payload' },
        { 'code' => 'platform.invalid_session', 'message' => 'Invalid session'   }
      ])

      # Should keep the HTTP status code from the first error added,
      # which was the "platform.malformed" from the merged set.

      expect(@r.errors.http_status_code).to eq(422)
    end

    it 'should "merge" empty errors' do
      e = Hoodoo::Errors.new

      expect( @r.add_errors( e ) ).to eq( false )
      @r.add_error( 'platform.invalid_session' )

      expect(@r.errors.errors).to eq([
        { 'code' => 'platform.invalid_session', 'message' => 'Invalid session' }
      ])

      # Should keep the HTTP status code from the first error added,
      # which was the "platform.malformed" from the merged set.

      expect(@r.errors.http_status_code).to eq(401)
    end
  end

  context '#add_precompiled_error' do
    it 'should let me add precompiled errors' do
      expect {
        @r.add_precompiled_error('test_domain.http_345_no_references 1', 'message 1', 'baz, foo 1')
        @r.add_precompiled_error('test_domain.http_345_no_references 2', 'message 2', 'baz, foo 2')
        @r.add_precompiled_error('test_domain.http_345_no_references 3', 'message 3', 'baz, foo 3')
      }.to_not raise_error

      expect(@r.errors.errors[0]).to eq({'code' => 'test_domain.http_345_no_references 1', 'message' => 'message 1', 'reference' => 'baz, foo 1'})
      expect(@r.errors.errors[1]).to eq({'code' => 'test_domain.http_345_no_references 2', 'message' => 'message 2', 'reference' => 'baz, foo 2'})
      expect(@r.errors.errors[2]).to eq({'code' => 'test_domain.http_345_no_references 3', 'message' => 'message 3', 'reference' => 'baz, foo 3'})
    end
  end

  context '#add_header, #get_header and #headers' do
    it 'should let me add headers' do
      @r.add_header( 'X-Foo', 'baz' )
      @r.add_header( 'X-Bar', 'boo' )

      expect(@r.get_header('X-Foo')).to eq('baz')
      expect(@r.get_header('X-FOO')).to eq('baz')
      expect(@r.get_header('x-foo')).to eq('baz')
      expect(@r.get_header('x-baR')).to eq('boo')
      expect(@r.get_header('random')).to eq(nil)
    end

    it 'should list headers' do
      @r.add_header( 'X-Foo', 'baz' )
      @r.add_header( 'x-bar', 'boo' )
      @r.add_header( 'X-BAZ', 'bin' )

      expect(@r.headers).to eq({'X-Foo' => 'baz', 'x-bar' => 'boo', 'X-BAZ' => 'bin'})
    end

    it 'should complain if I try to set the same header twice without the overwrite flag set' do
      @r.add_header( 'X-Foo', 'baz' )
      expect {
        @r.add_header( 'x-fOO', 'thing' )
      }.to raise_error(RuntimeError, "Hoodoo::Services::Response\#add_header: Value 'baz' already defined for header 'X-Foo'")
    end

    it 'should allow me to overwrite a header value' do
      @r.add_header( 'X-Foo', 'baz' )
      @r.add_header( 'x-fOO', 'thing', true )
      expect(@r.get_header('x-foo')).to eq('thing')
    end
  end

  context '#for_rack' do

    it 'should return default empty data correctly' do
      status, headers, body = @r.for_rack

      expected = JSON.generate({})
      expect(status).to eq(200)
      expect(headers).to eq({'content-length' => expected.length.to_s})
      expect(body).to eq([expected])
    end

    it 'should return header data correctly' do
      @r.add_header( 'X-Foo', :baz )
      @r.add_header( :'X-Bar', 'boo' )

      status, headers, body = @r.for_rack

      expected = JSON.generate({})
      expect(status).to eq(200)
      expect(headers).to eq({'x-foo' => 'baz', 'x-bar' => 'boo', 'content-length' => expected.length.to_s})
      expect(body).to eq([expected])
    end

    it 'should return error condition Rack data correctly' do
      @r.add_error('platform.malformed') # 422 status
      @r.add_error('platform.not_found', 'reference' => {:entity_name => 'hello'}) # 404 status

      @r.body = { this: 'should be ignored' }

      errors_hash = @r.errors.render(@r.instance_variable_get('@interaction_id'))
      status, headers, body = @r.for_rack

      expected = JSON.generate(errors_hash)
      expect(status).to eq(422) # From the first error we stored, not the second
      expect(headers).to eq({'content-length' => expected.length.to_s})
      expect(body).to eq([expected])
    end

    it 'should return non-error condition Rack data correctly with a Hash body' do
      response_hash = { this: 'should not be ignored' }
      @r.body = response_hash

      status, headers, body = @r.for_rack

      expected = JSON.generate(response_hash)
      expect(status).to eq(200) # From the first error we stored, not the second
      expect(headers).to eq({'content-length' => expected.length.to_s})
      expect(body).to eq([expected])
    end

    it 'returns non-error condition Rack data correctly with an Array body' do
      response_array = [ { this: 'should not be ignored' }, { neither: 'should this' } ]
      @r.body = response_array

      status, headers, body = @r.for_rack

      expected = JSON.generate({'_data' => response_array})
      expect(status).to eq(200) # From the first error we stored, not the second
      expect(headers).to eq({'content-length' => expected.length.to_s})
      expect(body).to eq([expected])
    end

    it 'returns non-error condition Rack data correctly with a dataset size' do
      response_array = [ { this: 'should not be ignored' }, { neither: 'should this' } ]
      @r.set_resources( response_array, response_array.count )

      status, headers, body = @r.for_rack

      expected = JSON.generate( { '_data' => response_array, '_dataset_size' => response_array.count } )
      expect( status    ).to eq( 200 )
      expect( headers   ).to eq( { 'content-length' => expected.length.to_s } )
      expect( body ).to eq( [ expected ] )
    end

    it 'returns non-error condition Rack data correctly with an estimated dataset size' do
      response_array = [ { this: 'should not be ignored' }, { neither: 'should this' } ]
      @r.set_estimated_resources( response_array, response_array.count )

      status, headers, body = @r.for_rack

      expected = JSON.generate( { '_data' => response_array, '_estimated_dataset_size' => response_array.count } )
      expect( status    ).to eq( 200 )
      expect( headers   ).to eq( { 'content-length' => expected.length.to_s } )
      expect( body ).to eq( [ expected ] )
    end

    it 'returns non-error condition Rack data correctly with both an accurate and an estimated dataset size' do
      response_array = [ { this: 'should not be ignored' }, { neither: 'should this' } ]

                @r.set_resources( response_array, response_array.count )
      @r.set_estimated_resources( response_array, response_array.count )

      status, headers, body = @r.for_rack

      expected = JSON.generate( { '_data'                   => response_array,
                                  '_dataset_size'           => response_array.count,
                                  '_estimated_dataset_size' => response_array.count } )

      expect( status    ).to eq( 200 )
      expect( headers   ).to eq( { 'content-length' => expected.length.to_s } )
      expect( body ).to eq( [ expected ] )
    end

    it 'should allow pre-encoded strings in the body' do
      @r.body = 'Hello World!'

      status, headers, body = @r.for_rack

      expect(status).to eq(200)
      expect(body).to eq(['Hello World!'])
    end

    it 'should raise an exception when the body is in an unsupported format' do
      @r.body = :foo

      expect {
        status, headers, body = @r.for_rack
      }.to raise_error(RuntimeError, "Hoodoo::Services::Response\#for_rack given unrecognised body data class 'Symbol'")
    end
  end

  context '#not_found' do
    let(:ident) { 'an_ident' }
    before { @r.not_found(ident) }

    it 'sets the generic.not_found code' do
      expect(@r.errors.errors.count).to eq(1)
      expect(@r.errors.errors.first['code']).to eq('generic.not_found')
    end
    it 'sets the reference to be the ident passed in' do
      expect(@r.errors.errors.first['reference']).to eq(ident)
    end
    it 'sets halt processing to true' do
      expect(@r.halt_processing?).to eq(true)
    end
  end

  context '#contemporary_exists' do
    let(:ident) { 'an_ident' }
    before { @r.contemporary_exists(ident) }

    it 'sets the generic.contemporary_exists code' do
      expect(@r.errors.errors.count).to eq(1)
      expect(@r.errors.errors.first['code']).to eq('generic.contemporary_exists')
    end
    it 'sets the reference to be the ident passed in' do
      expect(@r.errors.errors.first['reference']).to eq(ident)
    end
    it 'sets halt processing to true' do
      expect(@r.halt_processing?).to eq(true)
    end
  end

  context '#set_resources and #set_estimated_resources' do
    it '#set_resources sets #body and #dataset_size' do
      array = [ 1, 2, 3, 4 ]
      @r.set_resources( array, 4321 )
      expect( @r.body ).to match_array( array )
      expect( @r.dataset_size ).to eq( 4321 )
      expect( @r.estimated_dataset_size ).to be_nil
    end

    it '#set_estimated_resources sets #body and #estimated_dataset_size' do
      array = [ 4, 3, 2, 1 ]
      @r.set_estimated_resources( array, 1234 )
      expect( @r.body ).to match_array( array )
      expect( @r.dataset_size ).to be_nil
      expect( @r.estimated_dataset_size ).to eq( 1234 )
    end

    it 'both together set all properties with the most recent call setting #body' do
      array_1 = [ 1, 2, 3, 4 ]
      @r.set_resources( array_1, 4321 )

      array_2 = [ 4, 3, 2, 1 ]
      @r.set_estimated_resources( array_2, 1234 )

      expect( @r.body ).to match_array( array_2 )
      expect( @r.dataset_size ).to eq( 4321 )
      expect( @r.estimated_dataset_size ).to eq( 1234 )
    end
  end
end
