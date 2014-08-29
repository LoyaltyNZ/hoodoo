require 'spec_helper'

describe ApiTools::Presenters::Decimal do

  before do
    @inst = ApiTools::Presenters::Decimal.new('one',:precision => 20)
  end

  describe '#initialize' do
    it 'should raise an error if precision is not defined' do
      expect {
        ApiTools::Presenters::Decimal.new('one',:required => false)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#validate' do
    it 'should return [] when valid decimal' do
      expect(@inst.validate(BigDecimal.new(12.231,3))).to eq([])
    end

    it 'should return correct error when data is not a decimal' do
      errors = @inst.validate('asckn')

      err = [  {:code=>"generic.invalid_decimal", :message=>"Field `one` is an invalid decimal", :reference=>"one"}]
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

    it 'should return correct error with non decimal types' do
      err = [  {:code=>"generic.invalid_decimal", :message=>"Field `one` is an invalid decimal", :reference=>"one"}]

      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
        {:code=>"generic.invalid_decimal", :message=>"Field `ordinary.one` is an invalid decimal", :reference=>"ordinary.one"}
      ])
    end
  end
end