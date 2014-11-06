require 'spec_helper'

describe ApiTools::Presenters::Object do

  before do
    @inst = ApiTools::Presenters::Object.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid object' do
      expect(@inst.validate({}).errors).to eq([])
    end

    it 'should return correct error when data is not an object' do
      errors = @inst.validate(2347234)

      err = [{'code'=>"generic.invalid_object", 'message'=>"Field `one` is an invalid object", 'reference'=>"one"}]
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

    it 'should return correct error with non object types' do
      err = [{'code'=>"generic.invalid_object", 'message'=>"Field `one` is an invalid object", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(2123.23).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_object", 'message'=>"Field `ordinary.one` is an invalid object", 'reference'=>"ordinary.one"}
      ])
    end
  end
end