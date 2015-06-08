require 'spec_helper'

describe Hoodoo::Presenters::DateTime do

  before do
    @inst = Hoodoo::Presenters::DateTime.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid datetime (and be parsable by Ruby DateTime)' do
      #borrowed from http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/

      valid_iso_dates = [
        '2015-06-06T10:45:30.307Z',
        '2014-12-11T00:00:00Z',
        '2009-05-19T14:39:22-06:00',
        '2009-05-19T14:39:22+06:00',
        '2015-06-08T07:32:18.8746644+12:00',
        '2010-02-18T16:23:48.5' #time zone is optional, defaults to servers timezone
      ]

      for valid_date in valid_iso_dates
        DateTime.parse(valid_date)
        expect(@inst.validate(valid_date).errors).to eq([])
      end
    end

    it 'should NOT return [] when invalid datetime' do
      #stolen from http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/

      invalid_iso_dates = [
        "2007-04-05T24:00",
        "2009-",
        "2009-000",
        "2009-05-19",
        "2009-05-19 00:00",
        "2009-05-19 14",
        "2009-05-19 14.5.44",
        "2009-05-19 1439,55",
        "2009-05-19 143922.500",
        "2009-05-19 146922.500",
        "2009-05-19 14:",
        "2009-05-19 14:31",
        "2009-05-19 14:39:22",
        "2009-05-19 14:39:22+06:00",
        "2009-05-19 14:39:22+06a00",
        "2009-05-19 14:39:22-01",
        "2009-05-19 14:39:22-06:00",
        "2009-05-19 14a39a22",
        "2009-05-1914:39",
        "2009-05-19T14:3924",
        "2009-05-19T14:39Z",
        "2009-05-19T14a39r",
        "2009-05-19r14:39",
        "2009-0519",
        "2009-M511",
        "200905",
        "20090621T0545Z",
        "200912-01",
        "2009367",
        "2009M511",
        "2010-02-18T16,2283",
        "2010-02-18T16,25:23:48,444",
        "2010-02-18T16.23334444",
        "2010-02-18T16.5:23.35:48",
        "2010-02-18T16:23,25",
        "2010-02-18T16:23.33+0600",
        "2010-02-18T16:23.33.600",
        "2010-02-18T16:23.35:48",
        "2010-02-18T16:23.35:48.45",
        "2010-02-18T16:23.4",
        "2010-02-18T16:23:48,3-06:00",
        "2010-02-18T16:23:48,444"
      ]
      
      for invalid_date in invalid_iso_dates
        expect(@inst.validate(invalid_date).errors).not_to eq([])
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

    it 'should return correct error when data is not a datetime' do
      errors = @inst.validate('adskncasc')

      err = [  {'code'=>"generic.invalid_datetime", 'message'=>"Field `one` is an invalid ISO8601 datetime", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error when datetime is invalid' do
      errors = @inst.validate('2014-99-99T00:00:00Z')

      err = [  {'code'=>"generic.invalid_datetime", 'message'=>"Field `one` is an invalid ISO8601 datetime", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error with non datetime types' do
      err = [  {'code'=>"generic.invalid_datetime", 'message'=>"Field `one` is an invalid ISO8601 datetime", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate('2014-13-11').errors).to eq(err)
      expect(@inst.validate(34534.234).errors).to eq(err)
      expect(@inst.validate(38247).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_datetime", 'message'=>"Field `ordinary.one` is an invalid ISO8601 datetime", 'reference'=>"ordinary.one"}
      ])
    end
  end
end