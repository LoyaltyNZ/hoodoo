require 'spec_helper'

describe ApiTools::Presenters::Date do

  before do
    @inst = ApiTools::Presenters::Date.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid date' do
      expect(@inst.validate('2014-12-11')).to eq([])
    end

    it 'should not return error when not required and absent' do
      expect(@inst.validate(nil)).to eq([])
    end

    it 'should return error when required and absent' do
      @inst.required = true
      expect(@inst.validate(nil)).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `one` is required", 'reference'=>"one"}
      ])
    end

    it 'should return correct error when data is not a date' do
      errors = @inst.validate('adskncasc')

      err = [  {'code'=>"generic.invalid_date", 'message'=>"Field `one` is an invalid ISO8601 date", 'reference'=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error when date is invalid' do
      errors = @inst.validate('2014-99-99')

      err = [  {'code'=>"generic.invalid_date", 'message'=>"Field `one` is an invalid ISO8601 date", 'reference'=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non date types' do
      err = [  {'code'=>"generic.invalid_date", 'message'=>"Field `one` is an invalid ISO8601 date", 'reference'=>"one"}]

      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate('2014-12-11T00:00:00Z')).to eq(err)
      expect(@inst.validate(34534.234)).to eq(err)
      expect(@inst.validate(38247)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
        {'code'=>"generic.invalid_date", 'message'=>"Field `ordinary.one` is an invalid ISO8601 date", 'reference'=>"ordinary.one"}
      ])
    end
  end
end