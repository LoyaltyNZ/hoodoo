require 'spec_helper'

describe ApiTools::ServiceResponse do
  before do
    @r = ApiTools::ServiceResponse.new
  end

  it 'should acquire the expected default values when instantiated' do
    expect(@r.errors).to be_a(ApiTools::Errors)
    expect(@r.errors.has_errors?).to eq(false)
    expect(@r.http_status_code).to eq(200)
    expect(@r.body).to eq({})
    expect(@r.instance_variable_get('@headers')).to eq({})
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

  context '#add_header and #get_header' do
    it 'should let me add headers' do
      @r.add_header( 'X-Foo', 'baz' )
      @r.add_header( 'X-Bar', 'boo' )

      expect(@r.get_header('X-Foo')).to eq('baz')
      expect(@r.get_header('X-FOO')).to eq('baz')
      expect(@r.get_header('x-foo')).to eq('baz')
      expect(@r.get_header('x-baR')).to eq('boo')
      expect(@r.get_header('random')).to eq(nil)
    end

    it 'should complain if I try to set the same header twice without the overwrite flag set' do
      @r.add_header( 'X-Foo', 'baz' )
      expect {
        @r.add_header( 'x-fOO', 'thing' )
      }.to raise_error(RuntimeError, "ApiTools::ServiceResponse\#add_header: Value 'baz' already defined for header 'X-Foo'")
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

      expected = JSON.pretty_generate({})
      expect(status).to eq(200)
      expect(headers).to eq({'Content-Length' => expected.length.to_s})
      expect(body.body).to eq([expected])
    end

    it 'should return header data correctly' do
      @r.add_header( 'X-Foo', :baz )
      @r.add_header( :'X-Bar', 'boo' )

      status, headers, body = @r.for_rack

      expected = JSON.pretty_generate({})
      expect(status).to eq(200)
      expect(headers).to eq({'X-Foo' => 'baz', 'X-Bar' => 'boo', 'Content-Length' => expected.length.to_s})
      expect(body.body).to eq([expected])
    end

    it 'should return error condition Rack data correctly' do
      @r.add_error('platform.malformed') # 422 status
      @r.add_error('platform.not_found', 'reference' => {:entity_name => 'hello'}) # 404 status

      @r.body = { this: 'should be ignored' }

      errors_hash = @r.errors.render()
      status, headers, body = @r.for_rack

      expected = JSON.pretty_generate(errors_hash)
      expect(status).to eq(422) # From the first error we stored, not the second
      expect(headers).to eq({'Content-Length' => expected.length.to_s})
      expect(body.body).to eq([expected])
    end

    it 'should return non-error condition Rack data correctly with a Hash body' do
      response_hash = { this: 'should not be ignored' }
      @r.body = response_hash

      status, headers, body = @r.for_rack

      expected = JSON.pretty_generate(response_hash)
      expect(status).to eq(200) # From the first error we stored, not the second
      expect(headers).to eq({'Content-Length' => expected.length.to_s})
      expect(body.body).to eq([expected])
    end

    it 'should return non-error condition Rack data correctly with an Array body' do
      response_array = [ { this: 'should not be ignored' }, { neither: 'should this' } ]
      @r.body = response_array

      status, headers, body = @r.for_rack

      expected = JSON.pretty_generate({'_data' => response_array})
      expect(status).to eq(200) # From the first error we stored, not the second
      expect(headers).to eq({'Content-Length' => expected.length.to_s})
      expect(body.body).to eq([expected])
    end
  end
end
