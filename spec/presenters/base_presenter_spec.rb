require "spec_helper"
require "./lib/api_tools.rb"

describe '#schema' do

  describe '#validate' do

    before do

      class TestPresenter < ApiTools::Presenters::BasePresenter

        schema do
          integer :one, :required => true
          boolean :two, :required => true
          string :three, :length => 15, :required => false
          datetime :four
        end

      end

      class TestPresenter2 < ApiTools::Presenters::BasePresenter

        schema do
          object :four, :required => true do
            decimal :five, :precision => 20
            float :six
            date :seven, :required => true
            array :eight
          end
        end

      end

    end

    it 'should have a simple schema defined properly' do
      schema = TestPresenter.get_schema

      expect(schema.properties.count).to eq(4)
      expect(schema.properties[0]).to be_a(ApiTools::Presenters::Integer)
      expect(schema.properties[0].required).to eq(true)
      expect(schema.properties[1]).to be_a(ApiTools::Presenters::Boolean)
      expect(schema.properties[1].required).to eq(true)
      expect(schema.properties[2]).to be_a(ApiTools::Presenters::String)
      expect(schema.properties[2].required).to eq(false)
      expect(schema.properties[2].length).to eq(15)
      expect(schema.properties[3]).to be_a(ApiTools::Presenters::DateTime)
      expect(schema.properties[3].required).to eq(false)
    end

    it 'should have a nested schema defined properly' do
      schema = TestPresenter2.get_schema

      expect(schema.properties.length).to eq(1)
      expect(schema.properties[0]).to be_a(ApiTools::Presenters::Object)
      expect(schema.properties[0].properties.length).to eq(4)
      expect(schema.properties[0].properties[0]).to be_a(ApiTools::Presenters::Decimal)
      expect(schema.properties[0].properties[0].precision).to eq(20)
      expect(schema.properties[0].properties[1]).to be_a(ApiTools::Presenters::Float)
      expect(schema.properties[0].properties[2]).to be_a(ApiTools::Presenters::Date)
      expect(schema.properties[0].properties[2].required).to eq(true)
      expect(schema.properties[0].properties[3]).to be_a(ApiTools::Presenters::Array)
    end

    it 'should return no errors with a simple schema and valid data' do
      data = {
        :one => 1,
        :two => true,
        :three => 'hello',
      }

      expect(TestPresenter.validate(data)).to eq([])
    end

    it 'should return correct errors with a simple schema and invalid data' do
      data = {
        :one => 'test',
        :three => 9323423,
      }

      errors = TestPresenter.validate(data)
      expect(errors).to eq([
        {:code=>"generic.invalid_integer", :message=>"Field `one` is an invalid integer", :reference=>"one"},
        {:code=>"generic.required_field_missing", :message=>"Field `two` is required", :reference=>"two"},
        {:code=>"generic.invalid_string", :message=>"Field `three` is an invalid string", :reference=>"three"},
      ])
    end

    it 'should return correct errors if root object is required but not supplied and subobjects required' do

      data = {
      }

      errors = TestPresenter2.validate(data)
      expect(errors).to eq([
        {:code=>"generic.required_field_missing", :message=>"Field `four` is required", :reference=>"four"},
        {:code=>"generic.required_field_missing", :message=>"Field `four.seven` is required", :reference=>"four.seven"},
      ])
    end


  end
end
