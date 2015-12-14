require 'spec_helper'

describe Hoodoo::Presenters::Decimal do

  before do
    @inst = Hoodoo::Presenters::Decimal.new('one',:precision => 20)
  end

  describe '#initialize' do
    it 'should raise an error if precision is not defined' do
      expect {
        Hoodoo::Presenters::Decimal.new('one',:required => false)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#validate' do
    it 'should return [] when valid decimal' do
      expect(@inst.validate(BigDecimal.new(12.231,3)).errors).to eq([])
    end

    it 'should return correct error when data is not a decimal' do
      errors = @inst.validate('asckn')

      err = [  {'code'=>"generic.invalid_decimal", 'message'=>"Field `one` is an invalid decimal", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should not return error when not required and absent' do
      expect(@inst.validate(nil).errors).to eq([])
    end

    it 'should return error when required and absent' do
      @inst.required = true
      expect(@inst.validate(nil).errors).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `one` is required", 'reference'=>"one"}
      ])
    end

    it 'should return correct error with non decimal types' do
      err = [  {'code'=>"generic.invalid_decimal", 'message'=>"Field `one` is an invalid decimal", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_decimal", 'message'=>"Field `ordinary.one` is an invalid decimal", 'reference'=>"ordinary.one"}
      ])
    end
  end

end
