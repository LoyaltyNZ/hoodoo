require "spec_helper"
require "./lib/api_tools.rb"

describe '#schema' do

  before do

    # This exercises basic type definition using the Presenters DSL's #text
    # and #internationalised methods.
    #
    class ApiTools::Data::Types::Hello < ApiTools::Data::DocumentedPresenter
      schema do
        internationalised
        text :name, :required => true
      end
    end

    # This exercises basic resource definition with extended DSL methods #tags,
    # #uuid and #type, with the #object and #array parts checking methods from
    # both the extended and Presenters base DSL. The type reference is deeply
    # nested to make sure that internationalisation in the Hello type "taints"
    # the referencing type all the way up to the top level schema.

    class ApiTools::Data::Resources::World < ApiTools::Data::DocumentedPresenter
      schema do
        uuid :errors_id, :resource => :Errors
        tags :test_tags

        object :test_object, :required => true do
          object :nested_object do
            type :Hello
            string :obj_suffix, :length => 1
          end

          array :test_array do
            type :Hello
            string :ary_suffix, :length => 2
          end
        end
      end
    end
  end

  describe '#validate' do
    it 'should have schema defined properly' do
      schema = ApiTools::Data::Types::Hello.get_schema

      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(1)
      expect(schema.properties[:name]).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties[:name].required).to eq(true)

      schema = ApiTools::Data::Resources::World.get_schema

      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(3)
      expect(schema.properties[:errors_id]).to be_a(ApiTools::Data::DocumentedUUID)
      expect(schema.properties[:errors_id].required).to eq(false)
      expect(schema.properties[:errors_id].resource).to eq(:Errors)
      expect(schema.properties[:test_tags]).to be_a(ApiTools::Data::DocumentedTags)
      expect(schema.properties[:test_tags].required).to eq(false)
      expect(schema.properties[:test_object]).to be_a(ApiTools::Data::DocumentedObject)
      expect(schema.properties[:test_object].required).to eq(true)
      expect(schema.properties[:test_object].properties[:nested_object]).to be_a(ApiTools::Data::DocumentedObject)
      expect(schema.properties[:test_object].properties[:nested_object].required).to eq(false)
      expect(schema.properties[:test_object].properties[:nested_object].properties[:name]).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties[:test_object].properties[:nested_object].properties[:obj_suffix]).to be_a(ApiTools::Presenters::String)
      expect(schema.properties[:test_object].properties[:nested_object].properties[:obj_suffix].length).to eq(1)
      expect(schema.properties[:test_object].properties[:test_array]).to be_a(ApiTools::Data::DocumentedArray)
      expect(schema.properties[:test_object].properties[:test_array].required).to eq(false)
      expect(schema.properties[:test_object].properties[:test_array].properties[:name]).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties[:test_object].properties[:test_array].properties[:ary_suffix]).to be_a(ApiTools::Presenters::String)
      expect(schema.properties[:test_object].properties[:test_array].properties[:ary_suffix].length).to eq(2)
    end

    it 'should return no errors with valid data' do
      data = {
        :errors_id => ApiTools::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_ary => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1'                      },
            {                         :ary_suffix => '22' }
          ]
        }
      }

      expect(ApiTools::Data::Resources::World.validate(data)).to eq([])
    end

    it 'should return correct errors invalid data' do
      pending
      raise "OK"
    end
  end

  describe '#render' do
    it 'should render correctly' do
      pending
      raise "OK"
    end
  end

  describe '#parse' do
    it 'should parse correctly' do
      pending
      raise "OK"
    end
  end
end
