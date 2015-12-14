require 'spec_helper'

describe Hoodoo::Presenters::DateTime do

  before do
    @inst = Hoodoo::Presenters::DateTime.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid datetime' do
      expect(@inst.validate('2014-12-11T00:00:00Z').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00.0Z').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00.0000Z').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00.00000000Z').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00+12:30').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00-12:30').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00.0+12:30').errors).to eq([])
      expect(@inst.validate('2014-12-11T00:00:00.0-12:30').errors).to eq([])
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

    it 'should return correct error when datetime is invalid' do
      errors = @inst.validate('2014-99-99T00:00:00Z')

      err = [  {'code'=>"generic.invalid_datetime", 'message'=>"Field `one` is an invalid ISO8601 datetime", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error with non datetime types' do
      err = [  {'code'=>"generic.invalid_datetime", 'message'=>"Field `one` is an invalid ISO8601 datetime", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate('2014-12-11').errors).to eq(err)
      expect(@inst.validate(34534.234).errors).to eq(err)
      expect(@inst.validate(38247).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_datetime", 'message'=>"Field `ordinary.one` is an invalid ISO8601 datetime", 'reference'=>"ordinary.one"}
      ])
    end
  end

end
