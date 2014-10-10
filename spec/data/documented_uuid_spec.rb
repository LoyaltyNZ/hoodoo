require 'spec_helper'

describe ApiTools::Data::DocumentedUUID do

  before do
    @inst = ApiTools::Data::DocumentedTags.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return no errors when valid UUID' do
      expect(ApiTools::Data::DocumentedUUID.new('one').validate(ApiTools::UUID.generate())).to eq([])
    end

    it 'should return correct error when data is not a UUID-like string' do
      errors = ApiTools::Data::DocumentedUUID.new('one').validate('1234')

      err = [  {'code'=>"generic.invalid_string", 'message'=>"UUID `one` is of incorrect length `4` (should be `32`)", 'reference'=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error when data is not even a string' do
      errors = ApiTools::Data::DocumentedUUID.new('one').validate(1234)

      err = [  {'code'=>"generic.invalid_string", 'message'=>"UUID `one` is invalid", 'reference'=>"one"}]
      expect(errors).to eq(err)
    end
  end
end
