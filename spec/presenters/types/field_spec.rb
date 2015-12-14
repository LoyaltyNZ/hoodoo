require 'spec_helper'

describe Hoodoo::Presenters::Field do

  before do
    @inst = Hoodoo::Presenters::Field.new('one',:required => false)
  end

  describe '#initialise' do

    it 'should initialize correctly' do
      inst = Hoodoo::Presenters::Field.new('one',:required => true)
      expect(inst.name).to eq('one')
      expect(inst.required).to eq(true)
    end

    it 'should default required false' do
      inst = Hoodoo::Presenters::Field.new('two')
      expect(inst.name).to eq('two')
      expect(inst.required).to eq(false)
    end
  end

  describe '#validate' do
    it 'should return [] when not required when data nil' do
      errors = @inst.validate(nil)
      expect(errors.errors).to eq([])
    end

    it 'should return [] when not required when data not nil' do
      errors = @inst.validate(1)
      expect(errors.errors).to eq([])
    end

    it 'should return correct error when required and data is nil' do
      @inst.required = true
      errors = @inst.validate(nil)
      expect(errors.errors).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `one` is required", 'reference'=>"one"}
      ])
    end

    it 'should return correct error with path' do
      @inst.required = true
      errors = @inst.validate(nil,'ordinary')
      expect(errors.errors).to eq([
       {'code'=>"generic.required_field_missing", 'message'=>"Field `ordinary.one` is required", 'reference'=>"ordinary.one"}
      ])
    end
  end

  describe '#full_path' do

    it 'should return name.to_s if no path' do
      expect(@inst.full_path(nil)).to eq(@inst.name)
    end

    it 'should return name.to_s if path empty' do
      expect(@inst.full_path('')).to eq(@inst.name)
    end

    it 'should return paths if name nil' do
      @inst.name = nil
      expect(@inst.full_path('sdzcz')).to eq('sdzcz')
    end

    it 'should return paths if name empty' do
      @inst.name = ''
      expect(@inst.full_path('sdzcz')).to eq('sdzcz')
    end

    it 'should return path.name if path and name not nil or empty' do
      expect(@inst.full_path('sdzcz')).to eq('sdzcz.one')
    end
  end

end
