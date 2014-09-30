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
      expect(@inst.validate([])).to eq([])
    end

    it 'should return correct error when data is not a array' do
      errors = @inst.validate('asckn')

      err = [  {:code=>"generic.invalid_array", :message=>"Field `one` is an invalid array", :reference=>"one"}]
      expect(errors).to eq(err)
    end

    it 'should return correct error with non array types' do
      err = [  {:code=>"generic.invalid_array", :message=>"Field `one` is an invalid array", :reference=>"one"}]

      expect(@inst.validate('asckn')).to eq(err)
      expect(@inst.validate(34534)).to eq(err)
      expect(@inst.validate(2123.23)).to eq(err)
      expect(@inst.validate(true)).to eq(err)
      expect(@inst.validate({})).to eq(err)
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

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors).to eq([
        {:code=>"generic.invalid_array", :message=>"Field `ordinary.one` is an invalid array", :reference=>"ordinary.one"}
      ])
    end

    it 'should raise error if required but omitted' do
      data = {
      }

      errors = TestPresenter4.validate(data)
      expect(errors).to eq([
        {:code=>"generic.required_field_missing", :message=>"Field `an_array` is required", :reference=>"an_array"},
      ])

    end

    it 'should not insist on non-required entry fields in a required array' do
      data = {
        :an_array => [
          {},
          { :an_integer => 2 },
          { :a_datetime => Time.now.iso8601 }
        ]
      }

      errors = TestPresenter4.validate(data)
      expect(errors).to eq([])
    end

    it 'should validate all entry fields' do
      data = {
        :an_array => [
          {},
          { :an_integer => 'invalid' },
          { :a_datetime => 'invalid' }
        ]
      }

      errors = TestPresenter4.validate(data)
      expect(errors).to eq([
        {:code=>"generic.invalid_integer", :message=>"Field `an_array[1].an_integer` is an invalid integer", :reference=>"an_array[1].an_integer"},
        {:code=>"generic.invalid_datetime", :message=>"Field `an_array[2].a_datetime` is an invalid ISO8601 datetime", :reference=>"an_array[2].a_datetime"},
      ])
    end
  end
end
