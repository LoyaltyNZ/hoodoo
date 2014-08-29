require 'spec_helper'

describe ApiTools::Presenters::Array do

  before do
    @inst = ApiTools::Presenters::Array.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid array' do
      expect(@inst.validate([])).to eq([])
    end

    it 'should return correct error when data is not a array' do
      errors = @inst.validate('asckn')

      err = [  {:code=>"generic.invalid_array", :message=>"Field `one` is an invalid array", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non array types' do
      err = [  {:code=>"generic.invalid_array", :message=>"Field `one` is an invalid array", :reference=>"one"}]

      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(2123.23)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
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

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
        {:code=>"generic.invalid_array", :message=>"Field `ordinary.one` is an invalid array", :reference=>"ordinary.one"}
      ])
    end
  end
end