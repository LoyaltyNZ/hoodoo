require "spec_helper"
require "./lib/api_tools.rb"

describe '#schema' do

  before do

    class TestPresenter < ApiTools::Presenters::BasePresenter

      schema do
        integer :one, :required => true, :mapping => [ :map_one ]
        boolean :two, :required => true, :mapping => [ :map_two ]
        string :three, :length => 15, :required => false, :mapping => [ :map_three ]
        datetime :four, :mapping => [ :map_four, :time ]
      end

    end

    class TestPresenter2 < ApiTools::Presenters::BasePresenter

      schema do
        object :four, :required => true,  :mapping => [ :map_ten ] do
          decimal :five, :precision => 20,  :mapping => [ :map_ten, :map_five ]
          float :six,  :mapping => [ :map_ten, :map_six ]
          date :seven, :required => true,  :mapping => [ :map_root_one ]
          array :eight, :mapping => [ :map_ten, :map_eight ]
        end
      end

    end
  end

  describe '#validate' do
    it 'should have a simple schema defined properly' do
      schema = TestPresenter.get_schema

      expect(schema.properties.count).to eq(4)
      expect(schema.properties[:one]).to be_a(ApiTools::Presenters::Integer)
      expect(schema.properties[:one].required).to eq(true)
      expect(schema.properties[:two]).to be_a(ApiTools::Presenters::Boolean)
      expect(schema.properties[:two].required).to eq(true)
      expect(schema.properties[:three]).to be_a(ApiTools::Presenters::String)
      expect(schema.properties[:three].required).to eq(false)
      expect(schema.properties[:three].length).to eq(15)
      expect(schema.properties[:four]).to be_a(ApiTools::Presenters::DateTime)
      expect(schema.properties[:four].required).to eq(false)
    end

    it 'should have a nested schema defined properly' do
      schema = TestPresenter2.get_schema

      expect(schema.properties.length).to eq(1)
      expect(schema.properties[:four]).to be_a(ApiTools::Presenters::Object)
      expect(schema.properties[:four].properties.length).to eq(4)
      expect(schema.properties[:four].properties[:five]).to be_a(ApiTools::Presenters::Decimal)
      expect(schema.properties[:four].properties[:five].precision).to eq(20)
      expect(schema.properties[:four].properties[:six]).to be_a(ApiTools::Presenters::Float)
      expect(schema.properties[:four].properties[:seven]).to be_a(ApiTools::Presenters::Date)
      expect(schema.properties[:four].properties[:seven].required).to eq(true)
      expect(schema.properties[:four].properties[:eight]).to be_a(ApiTools::Presenters::Array)
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

  describe '#render' do
    it 'should render with correct mapping' do

      # 'four' maps into a subobject 'map_four.time'.
      data = {
        :one => 1,
        :two => true,
        :three => 'hello',
        :four => 'ten'
      }

      expect(TestPresenter.render(data)).to eq({
        :map_one=>1,
        :map_two=>true,
        :map_three=>"hello",
        :map_four=>{
          :time=>"ten"
        }
      })

      # 'four.seven' maps to 'map_root_one'
      data = {
        :four => {
          :five => 5,
          :seven => 'ten'
        }
      }

      expect(TestPresenter2.render(data)).to eq({
        :map_ten=>{
          :map_five=>5
        },
        :map_root_one=>"ten"
      })
    end
  end

  describe '#parse' do
    it 'should parse with correct mapping' do
      data = {
        :map_ten=>{
          :map_five=>5
        },
        :map_root_one=>"ten"
      }
      expect(TestPresenter2.parse(data)).to eq({
        :four=>{
          :five=>5,
          :seven=>"ten"
        }
      })
    end

    it 'should not include fields that do not exist in the input' do
      data = {
        :map_ten=>{
        },
        :map_root_one=>"ten"
      }
      expect(TestPresenter2.parse(data)).to eq({
        :four=>{
          :seven=>"ten"
        }
      })
    end
  end
end
