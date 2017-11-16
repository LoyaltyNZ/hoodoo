require 'spec_helper'

describe Hoodoo::Presenters::Decimal do

  before do
    @inst = Hoodoo::Presenters::Decimal.new('one',:precision => 20)
  end

  describe '#initialize' do
    it 'should raise an error if precision is not defined' do
      expect {
        Hoodoo::Presenters::Decimal.new('one',:required => false)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#validate' do
    it 'should return [] when valid decimal' do
      [
        '0',
        '0.0',
        '  .123245e2  ',
        '  .1_2_3_2_4_5E-2  ',
        '  0.123245e+2  ',
        '  0_3.123245E2  ',
        '  03.123245E2_3  ',
        '  12.3245  ',
        '  12.3245',
        '12.3245  ',
        '12.3245',
        '12.00',
        '12',
        '  -.123245e2  ',
        '  -.123245E2  ',
        '  -0.123245e2  ',
        '  -0.123245E2  ',
        '  -12.3245  ',
        '  -12.3245',
        '-12.3245  ',
        '-12.3245',
        '-12.00',
        '-12',
        '  +.123245e2  ',
        '  +.123245E2  ',
        '  +0.123245e2  ',
        '  +0.123245E2  ',
        '  +12.3245  ',
        '  +12.3245',
        '+12.3245  ',
        '+12.3245',
        '+12.00',
        '+12'
      ].each do | item |
        expect( @inst.validate( item ).errors ).to eq( [] )
      end

    end

    it 'should return correct error when data is not a decimal' do
      [
        'hello',
        '!23.00',
        '24!',
        '23.41 suffix',
        '+0.123245j2',
        '0.123245e+-2',
        '+-0.123245e2',
        '03_.123245E2',
        '03_.123245E2',
        '03._123245E2',
        '03.123245_E2',
        '03.123245E23_',
      ].each do | item |
        expect( @inst.validate( item ).errors ).to eq( [
          {
            'code'      => "generic.invalid_decimal",
            'message'   => "Field `one` is an invalid decimal",
            'reference' => "one"
          }
        ] )
      end
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

    it 'should return correct error with non decimal types' do
      err = [  {'code'=>"generic.invalid_decimal", 'message'=>"Field `one` is an invalid decimal", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_decimal", 'message'=>"Field `ordinary.one` is an invalid decimal", 'reference'=>"ordinary.one"}
      ])
    end
  end

end
