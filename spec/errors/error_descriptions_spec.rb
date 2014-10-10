require 'spec_helper'

describe ApiTools::ErrorDescriptions do

  # Test that DSL exceptions are raised as expected

  context 'incorrect definitions' do
    it 'should complain about missing message' do
      expect {
        ApiTools::ErrorDescriptions.new( :test_domain ) do
          error 'http_123', 'status' => 123
        end
      }.to raise_error(RuntimeError, "Error description options hash missing required key 'message'")
    end

    it 'should complain about missing status' do
      expect {
        ApiTools::ErrorDescriptions.new( :test_domain ) do
          error 'http_123', 'message' => 'hello world'
        end
      }.to raise_error(RuntimeError, "Error description options hash missing required key 'status'")
    end
  end

  # Test that a correctly called DSL leads to the Right Things happening when
  # called from the constructor.

  context 'correct definitions' do
    describe '#describe' do
      it 'should report correct custom definitions' do
        desc = ApiTools::ErrorDescriptions.new( :test_domain ) do
          error 'http_234_no_references',  'status' => 234, :message => '234 message'
          error 'http_345_has_reference',  :status => 345, 'message' => '345 message', 'reference' => [ :ref1 ]
          error 'http_456_has_references', 'status' => 456, 'message' => '456 message', :reference => [ :ref2, :ref3, :ref4 ]
        end

        expect(desc.describe('test_domain.http_234_no_references')).to eq('status' => 234, 'message' => '234 message')
        expect(desc.describe('test_domain.http_345_has_reference')).to eq('status' => 345, 'message' => '345 message', 'reference' => [ 'ref1' ])
        expect(desc.describe('test_domain.http_456_has_references')).to eq('status' => 456, 'message' => '456 message', 'reference' => [ 'ref2', 'ref3', 'ref4' ])
      end
    end
  end

  # Test that a correctly called DSL leads to the Right Things happening when
  # called from outside the constructor.

  context 'correct definitions' do
    before do
      @desc = ApiTools::ErrorDescriptions.new
      @desc.errors_for( :test_domain ) do
        error 'http_345_no_references',  'status' => 345, 'message' => '345 message'
        error 'http_456_has_reference',  'status' => 456, 'message' => '456 message', 'reference' => [ :ref1 ]
        error 'http_567_has_references', 'status' => 567, 'message' => '567 message', 'reference' => [ :ref2, :ref3, :ref4 ]
      end
    end

    # check errors are defined as expected by examining schema
    # check http code & default messages
    # check http code & custom messages
    # test exceptions for missing reference and references
    # test adding a reference, or many references, with commans
    # test adding extra reference data (appears at end)

    describe '#describe' do
      it 'should describe some default definitions' do
        expect(@desc.describe('platform.malformed')).to_not be_nil
        expect(@desc.describe('generic.malformed')).to_not be_nil
      end

      it 'should report correct custom definitions' do
        expect(@desc.describe('test_domain.http_345_no_references')).to eq('status' => 345, 'message' => '345 message')
        expect(@desc.describe('test_domain.http_456_has_reference')).to eq('status' => 456, 'message' => '456 message', 'reference' => [ 'ref1' ])
        expect(@desc.describe('test_domain.http_567_has_references')).to eq('status' => 567, 'message' => '567 message', 'reference' => [ 'ref2', 'ref3', 'ref4' ])
        expect(@desc.describe('test_domain.invalid')).to be_nil
      end
    end

    describe '#recognised?' do
      it 'should recognise default definitions' do
        expect(@desc.recognised?('platform.malformed')).to eq(true)
        expect(@desc.recognised?('generic.malformed')).to eq(true)
      end

      it 'should recognise custom definitions' do
        expect(@desc.recognised?('test_domain.http_345_no_references')).to eq(true)
        expect(@desc.recognised?('test_domain.http_456_has_reference')).to eq(true)
        expect(@desc.recognised?('test_domain.http_567_has_references')).to eq(true)
      end

      it 'should not recognise invalid definitions' do
        expect(@desc.recognised?('platform.invalid')).to eq(false)
        expect(@desc.recognised?('generic.invalid')).to eq(false)
        expect(@desc.recognised?('test_domain.invalid')).to eq(false)
        expect(@desc.recognised?('invalid.malformed')).to eq(false)
      end
    end
  end
end
