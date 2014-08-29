require 'spec_helper'

describe ApiTools::Presenters::Object do

  before do
    @inst = ApiTools::Presenters::Object.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid object' do
      expect(@inst.validate({})).to eq([])
    end

    it 'should return correct error when data is not a object' do
      errors = @inst.validate(2347234)

      err = [{:code=>"generic.invalid_object", :message=>"Field `one` is an invalid object", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non object types' do
      err = [  {:code=>"generic.invalid_object", :message=>"Field `one` is an invalid object", :reference=>"one"}]

      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(2123.23)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate(nil)).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
        {:code=>"generic.invalid_object", :message=>"Field `ordinary.one` is an invalid object", :reference=>"ordinary.one"}
      ])
    end
  end
end