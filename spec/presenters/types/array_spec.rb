require 'spec_helper'

describe ApiTools::Presenters::Array do

  before do
    @inst = ApiTools::Presenters::Array.new('one',:required => false)

    class TestPresenter4 < ApiTools::Presenters::BasePresenter

      schema do
        array :an_array, :required => true do
          integer :an_integer
          datetime :a_datetime
        end
        enum :an_enum, :from => [ :one, 'two', 3 ]
        text :some_text
      end

    end
  end

  describe '#validate' do
    it 'should return [] when valid array' do
      expect(@inst.validate([]).errors).to eq([])
    end

    it 'should return correct error when data is not a array' do
      errors = @inst.validate('asckn')

      err = [  {'code'=>"generic.invalid_array", 'message'=>"Field `one` is an invalid array", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error with non array types' do
      err = [  {'code'=>"generic.invalid_array", 'message'=>"Field `one` is an invalid array", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(2123.23).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
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

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_array", 'message'=>"Field `ordinary.one` is an invalid array", 'reference'=>"ordinary.one"}
      ])
    end

    it 'should raise error if required but omitted' do
      data = {
      }

      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `an_array` is required", 'reference'=>"an_array"},
      ])

    end

    it 'should not insist on non-required entry fields in a required array' do
      data = {
        'an_array' => [
          {},
          { :an_integer => 2 },
          { :a_datetime => Time.now.iso8601 }
        ]
      }

      data = ApiTools::Utilities.stringify(data)
      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([])
    end

    it 'should validate all entry fields' do
      data = {
        :an_array => [
          {},
          { :an_integer => 'invalid' },
          { :a_datetime => 'invalid' }
        ]
      }

      data = ApiTools::Utilities.stringify(data)
      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_integer", 'message'=>"Field `an_array[1].an_integer` is an invalid integer", 'reference'=>"an_array[1].an_integer"},
        {'code'=>"generic.invalid_datetime", 'message'=>"Field `an_array[2].a_datetime` is an invalid ISO8601 datetime", 'reference'=>"an_array[2].a_datetime"},
      ])
    end
  end

  describe '#render' do
    it 'should render correctly' do
      time = Time.now.iso8601
      data = {
        :an_enum => 'one',
        :an_array => [
          {},
          { :an_integer => 2 },
          { :a_datetime => time }
        ]
      }

      data = ApiTools::Utilities.stringify(data)
      expect(TestPresenter4.render(data)).to eq({
        'an_array' => [
          {
            'an_integer' => nil,
            'a_datetime' => nil
          },
          {
            'an_integer' => 2,
            'a_datetime' => nil
          },
          {
            'an_integer' => nil,
            'a_datetime' => time
          }
        ],
        'an_enum' => "one",
        'some_text' => nil
      })
    end
  end

  describe '#parse' do
    it 'should parse correctly' do
      time = Time.now.iso8601
      data = {
        :an_enum => 'one',
        'an_array' => [
          {},
          { :an_integer => 2 },
          { 'a_datetime' => time }
        ]
      }

      data = ApiTools::Utilities.stringify(data)
      expect(TestPresenter4.parse(data)).to eq({
        'an_array' => [
          {
          },
          {
            'an_integer' => 2
          },
          {
            'a_datetime' => time
          }
        ],
        'an_enum' => "one"
      })
    end
  end
end
