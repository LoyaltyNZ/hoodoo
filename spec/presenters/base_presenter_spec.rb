require "spec_helper"
require "./lib/api_tools.rb"

describe '#schema' do

  describe '#validate' do

    before do

      class TestPresenter < ApiTools::Presenters::BasePresenter

        schema do
          integer :one, :length => 20, :required => true
          boolean :two, :required => true
          string :three, :length => 20, :required => true
        end

      end

      class TestNestedPresenter < ApiTools::Presenters::BasePresenter

        schema do
          integer :one, :length => 20, :required => true
          boolean :two, :required => true
          string :three, :length => 20, :required => true
          object :four, :required => false do
            decimal :five, :precision => 20
            float :six
            date :seven
            object :eight, :required => true do
              datetime :nine
              array :ten
            end
          end
        end
        
      end

    end

    it 'should have the schema defined properly' do
      schema = TestPresenter.get_schema

      expect(schema.properties.count).to eq(3)
      expect(schema.properties[0]).to be_a(ApiTools::Presenters::Integer)
      expect(schema.properties[1]).to be_a(ApiTools::Presenters::Boolean)
      expect(schema.properties[2]).to be_a(ApiTools::Presenters::String)
      expect(schema.properties[2].length).to eq(20)
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

  end
end
