require 'spec_helper'

describe ApiTools::Presenters::Object do

  before do
    @inst = ApiTools::Presenters::Object.new('one',:required => false)

    class TestPresenterObject < ApiTools::Presenters::BasePresenter

      schema do
        # Intentional mix of strings and symbols in default object
        object :a_default_object, :default => { :an_integer => 42, 'some_text' => 'hello' } do
          integer :an_integer
          text :some_text
        end
        object :an_object_with_entry_defaults do
          integer :an_integer, :default => 42
          text :some_text
        end
      end

    end
  end

  describe '#validate' do
    it 'should return [] when valid object' do
      expect(@inst.validate({}).errors).to eq([])
    end

    it 'should return correct error when data is not an object' do
      errors = @inst.validate(2347234)

      err = [{'code'=>"generic.invalid_object", 'message'=>"Field `one` is an invalid object", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
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

    it 'should return correct error with non object types' do
      err = [{'code'=>"generic.invalid_object", 'message'=>"Field `one` is an invalid object", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(2123.23).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_object", 'message'=>"Field `ordinary.one` is an invalid object", 'reference'=>"ordinary.one"}
      ])
    end
  end


  describe '#render' do
    it 'renders correctly with whole-object default (1)' do
      data = nil

      expect(TestPresenterObject.render(data)).to eq({
        'a_default_object' => {
          'an_integer' => 42,
          'some_text' => 'hello'
        }
      })
    end

    it 'renders correctly with whole-object default (2)' do
      data = {}

      expect(TestPresenterObject.render(data)).to eq({
        'a_default_object' => {
          'an_integer' => 42,
          'some_text' => 'hello'
        }
      })
    end

    it 'must not override a provided object, even if nil' do
      data = { 'a_default_object' => nil }
      expect(TestPresenterObject.render(data)).to eq(data)
    end

    it 'must not override a provided object, even if "empty"' do
      data = { 'a_default_object' => {} }
      expect(TestPresenterObject.render(data)).to eq(data)
    end

    it 'provides default values for fields, where provided (1)' do
      data = {
        'a_default_object' => {
          'an_integer' => 20
        },
        'an_object_with_entry_defaults' => {
          'some_text' => 'hello'
        }
      }

      expect(TestPresenterObject.render(data)).to eq({
        'a_default_object' => {
          'an_integer' => 20
        },
        'an_object_with_entry_defaults' => {
          'an_integer' => 42,
          'some_text' => 'hello'
        }
      })
    end

    it 'must not overwrite explicit object nil with object-with-field-defaults' do
      data = {
        'a_default_object' => {
          'an_integer' => 20
        },
        'an_object_with_entry_defaults' => nil
      }

      expect(TestPresenterObject.render(data)).to eq(data)
    end

    it 'adds fields with defaults to empty objects' do
      data = {
        'a_default_object' => {
          'an_integer' => 59
        },
        'an_object_with_entry_defaults' => {}
      }

      expect(TestPresenterObject.render(data)).to eq({
        'a_default_object' => {
          'an_integer' => 59
        },
        'an_object_with_entry_defaults' => {
          'an_integer' => 42
        }
      })
    end

    it 'must not overwrite explicit field nil with field defaults' do
      data = {
        'a_default_object' => {
          'an_integer' => 20
        },
        'an_object_with_entry_defaults' => {
          'an_integer' => nil
        }
      }

      expect(TestPresenterObject.render(data)).to eq(data)
    end

    it 'must not overwrite explicit field value with field defaults' do
      data = {
        'a_default_object' => {
          'an_integer' => 20
        },
        'an_object_with_entry_defaults' => {
          'an_integer' => 21
        }
      }

      expect(TestPresenterObject.render(data)).to eq(data)
    end
  end
end