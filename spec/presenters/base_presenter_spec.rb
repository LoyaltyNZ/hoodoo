require "spec_helper"

describe '#schema' do

  before do

    class TestPresenter < ApiTools::Presenters::BasePresenter

      schema do
        integer :one, :required => true
        boolean :two, :required => true
        string :three, :length => 15, :required => false, :default => 'default_three'
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

    class TestPresenter3 < ApiTools::Presenters::BasePresenter

      schema do
        integer :one, :required => true
        object :four, :required => true do
          decimal :five, :precision => 20
          float :six
          date :seven, :required => true
          array :eight
        end
      end

    end

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
    it 'should have a simple schema defined properly' do
      schema = TestPresenter.get_schema

      expect(schema.properties.count).to eq(4)
      expect(schema.properties['one']).to be_a(ApiTools::Presenters::Integer)
      expect(schema.properties['one'].required).to eq(true)
      expect(schema.properties['two']).to be_a(ApiTools::Presenters::Boolean)
      expect(schema.properties['two'].required).to eq(true)
      expect(schema.properties['three']).to be_a(ApiTools::Presenters::String)
      expect(schema.properties['three'].required).to eq(false)
      expect(schema.properties['three'].length).to eq(15)
      expect(schema.properties['four']).to be_a(ApiTools::Presenters::DateTime)
      expect(schema.properties['four'].required).to eq(false)
    end

    it 'should have a nested schema defined properly' do
      schema = TestPresenter2.get_schema

      expect(schema.properties.length).to eq(1)
      expect(schema.properties['four']).to be_a(ApiTools::Presenters::Object)
      expect(schema.properties['four'].properties.length).to eq(4)
      expect(schema.properties['four'].properties['five']).to be_a(ApiTools::Presenters::Decimal)
      expect(schema.properties['four'].properties['five'].precision).to eq(20)
      expect(schema.properties['four'].properties['six']).to be_a(ApiTools::Presenters::Float)
      expect(schema.properties['four'].properties['seven']).to be_a(ApiTools::Presenters::Date)
      expect(schema.properties['four'].properties['seven'].required).to eq(true)
      expect(schema.properties['four'].properties['eight']).to be_a(ApiTools::Presenters::Array)
    end

    it 'should have a nested schema for arrays' do
      schema = TestPresenter4.get_schema
      expect(schema.properties.length).to eq(3)
      expect(schema.properties['an_array']).to be_a(ApiTools::Presenters::Array)
      expect(schema.properties['an_array'].required).to eq(true)
      expect(schema.properties['an_array'].properties.length).to eq(2)
      expect(schema.properties['an_array'].properties['an_integer']).to be_a(ApiTools::Presenters::Integer)
      expect(schema.properties['an_array'].properties['an_integer'].required).to eq(false)
      expect(schema.properties['an_array'].properties['a_datetime']).to be_a(ApiTools::Presenters::DateTime)
      expect(schema.properties['an_array'].properties['a_datetime'].required).to eq(false)
      expect(schema.properties['an_enum']).to be_a(ApiTools::Presenters::Enum)
      expect(schema.properties['an_enum'].required).to eq(false)
      expect(schema.properties['an_enum'].from).to eq(['one', 'two', '3'])
      expect(schema.properties['some_text']).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties['some_text'].required).to eq(false)
    end

    it 'should return no errors with a simple schema and valid data' do
      data = {
        'one' => 1,
        'two' => true,
        'three' => 'hello',
      }

      expect(TestPresenter.validate(data).errors).to eq([])
    end

    it 'should return correct errors with a simple schema and invalid data' do
      data = {
        'one' => 'test',
        'three' => 9323423,
      }

      errors = TestPresenter.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_integer", 'message'=>"Field `one` is an invalid integer", 'reference'=>"one"},
        {'code'=>"generic.required_field_missing", 'message'=>"Field `two` is required", 'reference'=>"two"},
        {'code'=>"generic.invalid_string", 'message'=>"Field `three` is an invalid string", 'reference'=>"three"},
      ])
    end
  end

  describe '#render' do
    it 'should ignore non-schema fields' do
      data = {
        'one' => 1,
        'three' => 'hello',
        'ignore' => 'me'
      }

      expect(TestPresenter.render(data)).to eq({
        'one'=>1,
        'three'=>'hello'
      })
    end

    it 'should omit fields when not supplied, without defaults' do
      data = {
        'one' => 1,
        'three' => 'hello'
      }

      expect(TestPresenter.render(data)).to eq({
        'one'=>1,
        'three'=>'hello'
      })
    end

    it 'should include default values where available for fields when not supplied' do
      data = {
        'one' => 1,
        'two' => 'hello',
      }

      expect(TestPresenter.render(data)).to eq({
        'one'=>1,
        'two'=>'hello',
        'three'=>'default_three',
      })
    end

    it 'should include fields with explicit nil values and not override with defaults' do
      data = {
        'one' => 1,
        'two' => nil,
        'three' => nil
      }

      expect(TestPresenter.render(data)).to eq({
        'one'=>1,
        'two'=>nil,
        'three'=>nil
      })
    end
  end
end
