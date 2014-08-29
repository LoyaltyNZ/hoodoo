require 'spec_helper'

describe ApiTools::Presenters::DateTime do

  before do
    @inst = ApiTools::Presenters::DateTime.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid datetime' do
      expect(@inst.validate('2014-12-11T00:00:00Z')).to eq([])
    end

    it 'should return correct error when data is not a datetime' do
      errors = @inst.validate('adskncasc')

      err = [  {:code=>"generic.invalid_datetime", :message=>"Field `one` is an invalid ISO8601 datetime", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error when datetime is invalid' do
      errors = @inst.validate('2014-99-99T00:00:00Z')

      err = [  {:code=>"generic.invalid_datetime", :message=>"Field `one` is an invalid ISO8601 datetime", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non datetime types' do
      err = [  {:code=>"generic.invalid_datetime", :message=>"Field `one` is an invalid ISO8601 datetime", :reference=>"one"}]
      
      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate('2014-12-11')).to eq(err)
      expect(@inst.validate(34534.234)).to eq(err)
      expect(@inst.validate(38247)).to eq(err)
      expect(@inst.validate(nil)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
      expect(@inst.validate([])).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
       {:code=>"generic.invalid_datetime", :message=>"Field `ordinary.one` is an invalid ISO8601 datetime", :reference=>"ordinary.one"}
      ])
    end
  end
end