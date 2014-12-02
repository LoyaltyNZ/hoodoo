require 'spec_helper'

describe ApiTools::Presenters::Enum do

  before do
    class TestPresenter4 < ApiTools::Presenters::Base

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

  describe '::schema' do
    it 'should raise an error if we use :from incorrectly' do
      expect {
        class ErroneousEnumTest < ApiTools::Presenters::Base
          schema do
            enum :from => "wrong!"
          end
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe '#validate' do
    it 'should insist on string values' do
      data = {
        :an_array => [],
        :an_enum => :one
      }

      data = ApiTools::Utilities.stringify(data)
      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_enum", 'message'=>"Field `an_enum` does not contain an allowed reference value from this list: `[\"one\", \"two\", \"3\"]`", 'reference'=>"an_enum"}
      ])
    end

    it 'should ensure only an enumerated value is given' do
      data = {
        :an_array => [],
        :an_enum => 'hello'
      }

      data = ApiTools::Utilities.stringify(data)
      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_enum", 'message'=>"Field `an_enum` does not contain an allowed reference value from this list: `[\"one\", \"two\", \"3\"]`", 'reference'=>"an_enum"}
      ])
    end

    it 'should be happy with valid values' do
      data = {
        :an_array => [],
        :an_enum => '3'
      }

      data = ApiTools::Utilities.stringify(data)
      errors = TestPresenter4.validate(data)
      expect(errors.errors).to eq([])
    end
  end
end

