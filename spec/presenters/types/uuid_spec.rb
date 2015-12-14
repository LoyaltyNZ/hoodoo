require 'spec_helper'

describe Hoodoo::Presenters::UUID do

  describe '#validate' do
    it 'should return no errors when valid UUID' do
      expect(Hoodoo::Presenters::UUID.new('one').validate(Hoodoo::UUID.generate()).errors).to eq([])
    end

    it 'should return correct error when data is not a UUID-like string (1)' do
      errors = Hoodoo::Presenters::UUID.new('one').validate('1234')

      err = [  {'code'=>"generic.invalid_uuid", 'message'=>"Field `one` is an invalid UUID", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error when data is not a UUID-like string (2)' do
      errors = Hoodoo::Presenters::UUID.new('one').validate('01234567890123456789012345678901z')

      err = [  {'code'=>"generic.invalid_uuid", 'message'=>"Field `one` is an invalid UUID", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error when data is not a UUID-like string (3)' do
      errors = Hoodoo::Presenters::UUID.new('one').validate('3ba258c0-4ce3-0132-9862-28373700b71c')

      err = [  {'code'=>"generic.invalid_uuid", 'message'=>"Field `one` is an invalid UUID", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error when data is not even a string (1)' do
      errors = Hoodoo::Presenters::UUID.new('one').validate(1234)

      err = [  {'code'=>"generic.invalid_uuid", 'message'=>"Field `one` is an invalid UUID", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error when data is not even a string (2)' do
      errors = Hoodoo::Presenters::UUID.new('one').validate(Hoodoo::UUID.generate().to_sym)

      err = [  {'code'=>"generic.invalid_uuid", 'message'=>"Field `one` is an invalid UUID", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end
  end

end
