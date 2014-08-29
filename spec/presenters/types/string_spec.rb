require 'spec_helper'

describe ApiTools::Presenters::String do

  before do
    @inst = ApiTools::Presenters::String.new('one',:required => false, :length => 10)
  end

  describe '#initialize' do
    it 'should raise an error if length is not defined' do
      expect {
        ApiTools::Presenters::String.new('one',:required => false)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#validate' do
    it 'should return [] when valid string' do
      expect(@inst.validate('ascinas')).to eq([])
    end

    it 'should return correct error when data is not a string' do
      errors = @inst.validate(23424)

      err = [  {:code=>"generic.invalid_string", :message=>"Field `one` is an invalid string", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should not return error when not required and absent' do
      expect(@inst.validate(nil)).to eq([])
    end

    it 'should return error when required and absent' do
      @inst.required = true
      expect(@inst.validate(nil)).to eq([
        {:code=>"generic.required_field_missing", :message=>"Field `one` is required", :reference=>"one"}
      ])
    end

    it 'should return correct error with non string types' do
      err = [  {:code=>"generic.invalid_string", :message=>"Field `one` is an invalid string", :reference=>"one"}]

      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(234234.44)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate(234234,'ordinary')
      expect(errors).to eq([
        {:code=>"generic.invalid_string", :message=>"Field `ordinary.one` is an invalid string", :reference=>"ordinary.one"}
      ])
    end

    it 'should return correct error when length is exceeded' do
      errors = @inst.validate('12345678901')
      expect(errors).to eq([
        {:code=>"generic.max_length_exceeded", :message=>"Field `one` is larger than max length `10`", :reference=>"one"}
      ])
    end
  end
end