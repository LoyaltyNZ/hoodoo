require 'spec_helper'

describe ApiTools::Presenters::Float do

  before do
    @inst = ApiTools::Presenters::Float.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid float' do
      expect(@inst.validate(12.231)).to eq([])
    end

    it 'should return correct error when data is not a float' do
      errors = @inst.validate('asckn')

      err = [  {:code=>"generic.invalid_float", :message=>"Field `one` is an invalid float", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non float types' do
      err = [  {:code=>"generic.invalid_float", :message=>"Field `one` is an invalid float", :reference=>"one"}]
      
      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate(nil)).to eq(err)
      expect(@inst.validate({})).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
       {:code=>"generic.invalid_float", :message=>"Field `ordinary.one` is an invalid float", :reference=>"ordinary.one"}
      ])
    end
  end
end