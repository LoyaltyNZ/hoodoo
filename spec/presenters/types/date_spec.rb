require 'spec_helper'

describe Hoodoo::Presenters::Date do

  before do
    @inst = Hoodoo::Presenters::Date.new('one',:required => false)
  end

  # At the time of writing, the Date type code calls through
  # to Utility for the back-end validation. In case that ever
  # changes, though, many of these tests are replicated in
  # utility_spec.rb.
  #
  describe '#validate' do
    it 'should return [] when valid date' do
      expect(@inst.validate('2014-12-11').errors).to eq([])
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

    it 'should return correct error when date is invalid' do
      errors = @inst.validate('2014-99-99')

      err = [  {'code'=>"generic.invalid_date", 'message'=>"Field `one` is an invalid ISO8601 date", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error with non date types' do
      err = [  {'code'=>"generic.invalid_date", 'message'=>"Field `one` is an invalid ISO8601 date", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate('2014-12-11T00:00:00Z').errors).to eq(err)
      expect(@inst.validate(34534.234).errors).to eq(err)
      expect(@inst.validate(38247).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_date", 'message'=>"Field `ordinary.one` is an invalid ISO8601 date", 'reference'=>"ordinary.one"}
      ])
    end
  end
end