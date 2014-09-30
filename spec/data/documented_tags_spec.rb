require 'spec_helper'

describe ApiTools::Data::DocumentedTags do

  # This is just a copy of the ApiTools::Presenters::Text tests, which is in
  # turn a copy of ApiTools::Presenters::String with minor changes (at the
  # time of writing). The intent is to provide coverage for potential changes
  # to the tag implementation in future, even though right now it's just a
  # direct inheritance from Text with no changes.

  before do
    @inst = ApiTools::Data::DocumentedTags.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return no errors when valid string' do
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
  end
end