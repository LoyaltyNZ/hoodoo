require 'spec_helper'

describe ApiTools::Errors do
  before do
    @desc = ApiTools::ErrorDescriptions.new( :test_domain ) do
      error 'http_345_no_references',  status: 345, message: '345 message'
      error 'http_456_has_reference',  status: 456, message: '456 message', reference: [ :ref1 ]
      error 'http_567_has_references', status: 567, message: '567 message', reference: [ :ref2, :ref3, :ref4 ]
    end

    @errors = ApiTools::Errors.new(@desc)
  end

  describe '#initialize' do
    it 'should have correct descriptions' do
      # Read the ivars to compare objects. The "@descriptions" variable in an
      # ErrorDescriptions instance gives its descriptions hash. The same-named
      # variable in the Errors instance gives the ErrorDescriptions instances,
      # so the chained "instance_variable_get" call in the second and third
      # test is correct.

      expect(ApiTools::Errors::DEFAULT_ERROR_DESCRIPTIONS.instance_variable_get('@descriptions')).to eq(ApiTools::ErrorDescriptions.new().instance_variable_get('@descriptions'))
      expect(ApiTools::Errors.new().instance_variable_get('@descriptions').instance_variable_get('@descriptions')).to eq(ApiTools::ErrorDescriptions.new().instance_variable_get('@descriptions'))
      expect(@errors.instance_variable_get('@descriptions').instance_variable_get('@descriptions')).to eq(@desc.instance_variable_get('@descriptions'))
    end

    it 'should have a UUID, empty errors and a 500 code' do
      expect(@errors.uuid.size).to eq(32)
      expect(@errors.errors).to be_empty
      expect(@errors.http_status_code).to eq(500)
    end
  end

  describe '#add_error, #has_errors?' do
    it 'should let me add a generic error and tell me it was added' do
      expect(@errors.has_errors?).to eq(false)
      @errors.add_error('platform.malformed')
      expect(@errors.has_errors?).to eq(true)
      expect(@errors.errors).to_not be_empty
    end

    it 'should let me add simple custom errors' do
      expect {
        @errors.add_error('test_domain.http_345_no_references')
        @errors.add_error('test_domain.http_345_no_references', :message => 'foo 1')
        @errors.add_error('test_domain.http_345_no_references', :message => 'foo 2', :reference => { :bar => 'baz', :baz => 'foo' })
      }.to_not raise_error

      expect(@errors.errors[-3]).to eq({:code => 'test_domain.http_345_no_references', :message => '345 message'})
      expect(@errors.errors[-2]).to eq({:code => 'test_domain.http_345_no_references', :message => 'foo 1'})
      expect(@errors.errors[-1]).to eq({:code => 'test_domain.http_345_no_references', :message => 'foo 2', :reference => 'baz,foo'})
    end

    it 'should complain about missing fields' do
      expect {
        @errors.add_error('test_domain.http_456_has_reference')
      }.to raise_error(RuntimeError, "In #add_error: Reference hash missing required keys: 'ref1'")

      expect {
        @errors.add_error('test_domain.http_567_has_references')
      }.to raise_error(RuntimeError, "In #add_error: Reference hash missing required keys: 'ref2, ref3, ref4'")

      expect {
        @errors.add_error('test_domain.http_567_has_references', :reference => {:ref3 => "hello"})
      }.to raise_error(RuntimeError, "In #add_error: Reference hash missing required keys: 'ref2, ref4'")
    end

    it 'should let me specify mandatory reference data' do
      expect {
        @errors.add_error('test_domain.http_456_has_reference', :reference => {:ref1 => 'ref1-data'})
      }.to_not raise_error

      expect(@errors.errors[-1]).to eq({:code => 'test_domain.http_456_has_reference', :message => '456 message', :reference => 'ref1-data'})

      expect {
        @errors.add_error('test_domain.http_456_has_reference', :message => 'ref1-test', :reference => {:ref1 => 'ref1-data'})
      }.to_not raise_error

      expect(@errors.errors[-1]).to eq({:code => 'test_domain.http_456_has_reference', :message => 'ref1-test', :reference => 'ref1-data'})

      expect {
        @errors.add_error('test_domain.http_567_has_references', :reference => {:ref2 => 'ref2-data', :ref3 => 'ref3-data', :ref4 => 'ref4-data'})
      }.to_not raise_error

      expect(@errors.errors[-1]).to eq({:code => 'test_domain.http_567_has_references', :message => '567 message', :reference => 'ref2-data,ref3-data,ref4-data'})
    end

    it 'should let me specify additional reference data and list it after mandatory data' do
      expect {
        @errors.add_error('test_domain.http_567_has_references', :reference => {:add2 => 'add2-data', :ref2 => 'ref2-data', :add1 => 'add1-data', :ref3 => 'ref3-data', :ref4 => 'ref4-data'})
      }.to_not raise_error

      expect(@errors.errors[-1]).to eq({:code => 'test_domain.http_567_has_references', :message => '567 message', :reference => 'ref2-data,ref3-data,ref4-data,add2-data,add1-data'})
    end
  end

  describe '#clear_errors' do
    it 'should correctly clear errors' do
      @errors.clear_errors
      expect(@errors.has_errors?).to eq(false)
      expect(@errors.errors).to be_empty

      @errors.add_error('platform.malformed')
      expect(@errors.has_errors?).to eq(true)
      expect(@errors.errors).to_not be_empty

      @errors.clear_errors
      expect(@errors.has_errors?).to eq(false)
      expect(@errors.errors).to be_empty
    end
  end

  describe '#render' do
    it 'should store before rendering' do
      @errors.clear_errors
      @errors.add_error('platform.malformed')

      expect(ApiTools::Logger).to receive(:error)
      expect(@errors).to receive(:store!).and_call_original

      data = @errors.render()
      expect(data[:errors]).to be_a(Array)
      expect(data[:errors].count).to eq(1)
      expect(data[:errors][0][:code]).to eq('platform.malformed')
      expect(data[:errors][0][:message]).to be_a(String)
      expect(data[:errors][0][:message].size).to_not eq(0)
      expect(data[:errors][0][:reference]).to be_nil
      expect(data[:id]).to be_a(String)
      expect(data[:id].size).to eq(32)
      expect(data[:kind]).to eq('Errors')
      expect(data[:created_at]).to be_a(String)
      expect {
        raise "Broken or missing created_at" if Date.parse(data[:created_at]).nil?
      }.to_not raise_error
    end
  end

  describe 'comma escaping' do
    it 'should escape commas' do
      str = @errors.send(:escape_commas, "This, that, one \\ another")
      expect(str).to eq("This\\, that\\, one \\\\ another")
    end

    it 'should unescape commas' do
      str = @errors.send(:escape_commas, "This, that, one \\ another")
      str = @errors.send(:unescape_commas, str)
      expect(str).to eq("This, that, one \\ another")
    end

    it 'should unpack an escaped comma separated list' do
      ary = [ 'this, that', 'one \\ another' ]
      str = @errors.send(:escape_commas, ary[0])
      str << ',' << @errors.send(:escape_commas, ary[1])
      expect(@errors.unjoin_and_unescape_commas(str)).to eq(ary)
    end

    it 'should escape reference data, which should be recoverable' do
      @errors.clear_errors
      @errors.add_error('test_domain.http_567_has_references', :reference => {:ref2 => 'ref \\ 2 data', :ref3 => 'ref, 3, data', :ref4 => 'ref4-data'})

      expect(ApiTools::Logger).to receive(:error) # Keeps stdout quiet!
      expect(@errors).to receive(:store!).and_call_original

      rendered = @errors.render
      ary = @errors.unjoin_and_unescape_commas(rendered[:errors][0][:reference])
      expect(ary).to eq(['ref \\ 2 data', 'ref, 3, data', 'ref4-data'])
    end
  end
end
