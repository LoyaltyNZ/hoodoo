require "spec_helper"

describe '#schema' do

  before do

    class TestPresenter < Hoodoo::Presenters::Base

      schema do
        integer :one, :required => true
        boolean :two, :required => true
        string :three, :length => 15, :required => false, :default => 'default_three'
        datetime :four
      end

    end

    class TestPresenter2 < Hoodoo::Presenters::Base

      schema do
        object :four, :required => true do
          decimal :five, :precision => 20
          float :six
          date :seven, :required => true
          array :eight
        end
      end

    end

    class TestPresenter3 < Hoodoo::Presenters::Base

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

    class TestPresenter4 < Hoodoo::Presenters::Base

      schema do
        array :an_array, :required => true do
          integer :an_integer
          datetime :a_datetime
        end
        enum :an_enum, :from => [ :one, 'two', 3 ]
        text :some_text
      end

    end


    # Just in case someone's deliberately excluding other source files to
    # check on code coverage...
    #
    module Hoodoo
      module Data
        module Types
        end
        module Resources
        end
      end
    end

    # This exercises basic type definition using the Presenters DSL's #text
    # and #internationalised methods.
    #
    class Hoodoo::Data::Types::Hello < Hoodoo::Presenters::Base
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

    class Hoodoo::Data::Resources::World < Hoodoo::Presenters::Base
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

    # Check the 'resource' reference part of the DSL works too

    class Hoodoo::Data::Resources::HelloWorld < Hoodoo::Presenters::Base
      schema do
        type :Hello
        resource :World
      end
    end

    class NastyNesting < Hoodoo::Presenters::Base
      schema do
        array :outer_array, :required => true do
          text :one, :required => true
          text :two, :required => true
          array :middle_array, :required => true do
            text :three, :required => true
            text :four, :required => true
            array :inner_array, :required => true do
              text :five, :required => true
              text :six, :required => true
              object :inner_object, :required => true do
                text :seven, :required => true
              end
            end
          end
        end
      end
    end

    # For testing resource validation for internationalised (or not) resources.

    class Internationalised < Hoodoo::Presenters::Base
      schema do
        internationalised
      end
    end

    class NotInternationalised < Hoodoo::Presenters::Base
      schema do
      end
    end

    # For testing hashes with type references

    class Internationalised2 < Hoodoo::Presenters::Base
      schema do
        internationalised
        text :hello
      end
    end

    class HashGainsInternationalisation < Hoodoo::Presenters::Base
      schema do
        hash :inter do
          keys do
            type :Internationalised2
          end
        end
      end
    end

    class HashGainsInternationalisation2 < Hoodoo::Presenters::Base
      schema do
        hash :inter do
          key :one do
            text :foo
          end
          key :two do
            type :Internationalised2
          end
        end
      end
    end
  end

  describe '#validate' do
    it 'should have a simple schema defined properly' do
      schema = TestPresenter.get_schema

      expect(schema.properties.count).to eq(4)
      expect(schema.properties['one']).to be_a(Hoodoo::Presenters::Integer)
      expect(schema.properties['one'].required).to eq(true)
      expect(schema.properties['two']).to be_a(Hoodoo::Presenters::Boolean)
      expect(schema.properties['two'].required).to eq(true)
      expect(schema.properties['three']).to be_a(Hoodoo::Presenters::String)
      expect(schema.properties['three'].required).to eq(false)
      expect(schema.properties['three'].length).to eq(15)
      expect(schema.properties['four']).to be_a(Hoodoo::Presenters::DateTime)
      expect(schema.properties['four'].required).to eq(false)
    end

    it 'should have a nested schema defined properly' do
      schema = TestPresenter2.get_schema

      expect(schema.properties.length).to eq(1)
      expect(schema.properties['four']).to be_a(Hoodoo::Presenters::Object)
      expect(schema.properties['four'].properties.length).to eq(4)
      expect(schema.properties['four'].properties['five']).to be_a(Hoodoo::Presenters::Decimal)
      expect(schema.properties['four'].properties['five'].precision).to eq(20)
      expect(schema.properties['four'].properties['six']).to be_a(Hoodoo::Presenters::Float)
      expect(schema.properties['four'].properties['seven']).to be_a(Hoodoo::Presenters::Date)
      expect(schema.properties['four'].properties['seven'].required).to eq(true)
      expect(schema.properties['four'].properties['eight']).to be_a(Hoodoo::Presenters::Array)
    end

    it 'should have a nested schema for arrays' do
      schema = TestPresenter4.get_schema
      expect(schema.properties.length).to eq(3)
      expect(schema.properties['an_array']).to be_a(Hoodoo::Presenters::Array)
      expect(schema.properties['an_array'].required).to eq(true)
      expect(schema.properties['an_array'].properties.length).to eq(2)
      expect(schema.properties['an_array'].properties['an_integer']).to be_a(Hoodoo::Presenters::Integer)
      expect(schema.properties['an_array'].properties['an_integer'].required).to eq(false)
      expect(schema.properties['an_array'].properties['a_datetime']).to be_a(Hoodoo::Presenters::DateTime)
      expect(schema.properties['an_array'].properties['a_datetime'].required).to eq(false)
      expect(schema.properties['an_enum']).to be_a(Hoodoo::Presenters::Enum)
      expect(schema.properties['an_enum'].required).to eq(false)
      expect(schema.properties['an_enum'].from).to eq(['one', 'two', '3'])
      expect(schema.properties['some_text']).to be_a(Hoodoo::Presenters::Text)
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

    it 'should have nested complex schema defined properly' do

      schema = Hoodoo::Data::Types::Hello.get_schema

      expect(Hoodoo::Data::Types::Hello.is_internationalised?()).to eq(true)
      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(1)
      expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['name'].required).to eq(true)

      schema = Hoodoo::Data::Resources::World.get_schema

      expect(Hoodoo::Data::Resources::World.is_internationalised?()).to eq(true)
      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(3)
      expect(schema.properties['errors_id']).to be_a(Hoodoo::Presenters::UUID)
      expect(schema.properties['errors_id'].required).to eq(false)
      expect(schema.properties['errors_id'].resource).to eq(:Errors)
      expect(schema.properties['test_tags']).to be_a(Hoodoo::Presenters::Tags)
      expect(schema.properties['test_tags'].required).to eq(false)
      expect(schema.properties['test_object']).to be_a(Hoodoo::Presenters::Object)
      expect(schema.properties['test_object'].required).to eq(true)
      expect(schema.properties['test_object'].properties['nested_object']).to be_a(Hoodoo::Presenters::Object)
      expect(schema.properties['test_object'].properties['nested_object'].required).to eq(false)
      expect(schema.properties['test_object'].properties['nested_object'].properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix']).to be_a(Hoodoo::Presenters::String)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix'].length).to eq(1)
      expect(schema.properties['test_object'].properties['test_array']).to be_a(Hoodoo::Presenters::Array)
      expect(schema.properties['test_object'].properties['test_array'].required).to eq(false)
      expect(schema.properties['test_object'].properties['test_array'].properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix']).to be_a(Hoodoo::Presenters::String)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix'].length).to eq(2)

      schema = Hoodoo::Data::Resources::HelloWorld.get_schema

      expect(Hoodoo::Data::Resources::World.is_internationalised?()).to eq(true)
      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(4)
      expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['name'].required).to eq(true)
      expect(schema.properties['errors_id']).to be_a(Hoodoo::Presenters::UUID)
      expect(schema.properties['errors_id'].required).to eq(false)
      expect(schema.properties['errors_id'].resource).to eq(:Errors)
      expect(schema.properties['test_tags']).to be_a(Hoodoo::Presenters::Tags)
      expect(schema.properties['test_tags'].required).to eq(false)
      expect(schema.properties['test_object']).to be_a(Hoodoo::Presenters::Object)
      expect(schema.properties['test_object'].required).to eq(true)
      expect(schema.properties['test_object'].properties['nested_object']).to be_a(Hoodoo::Presenters::Object)
      expect(schema.properties['test_object'].properties['nested_object'].required).to eq(false)
      expect(schema.properties['test_object'].properties['nested_object'].properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix']).to be_a(Hoodoo::Presenters::String)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix'].length).to eq(1)
      expect(schema.properties['test_object'].properties['test_array']).to be_a(Hoodoo::Presenters::Array)
      expect(schema.properties['test_object'].properties['test_array'].required).to eq(false)
      expect(schema.properties['test_object'].properties['test_array'].properties['name']).to be_a(Hoodoo::Presenters::Text)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix']).to be_a(Hoodoo::Presenters::String)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix'].length).to eq(2)
    end

    it 'should return no errors with valid data for type only' do
      data = {
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1' }
          ]
        }
      }

      data = Hoodoo::Utilities.stringify(data)
      expect(Hoodoo::Data::Resources::World.validate(data, false).errors).to eq([])
    end

    it 'should return no errors with valid data for resource' do
      data = {
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1' }
          ]
        }
      }

      data = Hoodoo::Utilities.stringify(data)
      rendered = Hoodoo::Data::Resources::World.render(
        data,
        Hoodoo::UUID.generate,
        Time.now
      )

      expect(Hoodoo::Data::Resources::World.validate(rendered, true).errors).to eq([])
    end

    it 'should return correct errors invalid data' do
      data = {
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!!!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1'                      },
            {                         :ary_suffix => 22   }
          ]
        }
      }

      data = Hoodoo::Utilities.stringify(data)
      expect(Hoodoo::Data::Resources::World.validate(data, false).errors).to eq([
        {
          'code' => 'generic.invalid_string',
          'message' => 'Field `test_object.nested_object.obj_suffix` is longer than maximum length `1`',
          'reference' => "test_object.nested_object.obj_suffix"
        },
        {
          'code' => 'generic.required_field_missing',
          'message' => 'Field `test_object.test_array[2].name` is required',
          'reference' => "test_object.test_array[2].name"
        },
        {
          'code' => 'generic.invalid_string',
          'message' => 'Field `test_object.test_array[2].ary_suffix` is an invalid string',
          'reference' => "test_object.test_array[2].ary_suffix"
        }
      ])
    end

    it 'should return correct paths in errors for deeply nested cases' do

      # The array must be present, but that doesn't tell us anything about
      # the contents yet so we only have one error.

      data = {}
      expect(NastyNesting.validate(data, false).errors).to eq([
        {
          'code' => 'generic.required_field_missing',
          'message' => 'Field `outer_array` is required',
          'reference' => "outer_array"
        }
      ])

      # The outer array is present but empty. That's allowed. If we had
      # added entries, then their requirements would apply.

      data = {
        :outer_array => []
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([])

      # The outer array is present and has two entries that omit required
      # fields, so we expect errors for all of them.

      data = {
        :outer_array => [{}, {}]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].one` is required',          'reference' => "outer_array[0].one"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].two` is required',          'reference' => "outer_array[0].two"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array` is required', 'reference' => "outer_array[0].middle_array"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[1].one` is required',          'reference' => "outer_array[1].one"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[1].two` is required',          'reference' => "outer_array[1].two"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[1].middle_array` is required', 'reference' => "outer_array[1].middle_array"}
      ])

      # ...and follow that pattern for nested items...

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => []
          }
        ]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([])

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => [{},{}]
          }
        ]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].three` is required',       'reference' => "outer_array[0].middle_array[0].three"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].four` is required',        'reference' => "outer_array[0].middle_array[0].four"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array` is required', 'reference' => "outer_array[0].middle_array[0].inner_array"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[1].three` is required',       'reference' => "outer_array[0].middle_array[1].three"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[1].four` is required',        'reference' => "outer_array[0].middle_array[1].four"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[1].inner_array` is required', 'reference' => "outer_array[0].middle_array[1].inner_array"}
      ])

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => [
              {
                :three => 'here',
                :four  => 'here',
                :inner_array => []
              }
            ]
          }
        ]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([])

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => [
              {
                :three => 'here',
                :four  => 'here',
                :inner_array => [{},{}]
              }
            ]
          }
        ]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[0].five` is required',               'reference' => "outer_array[0].middle_array[0].inner_array[0].five"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[0].six` is required',                'reference' => "outer_array[0].middle_array[0].inner_array[0].six"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[0].inner_object` is required',       'reference' => "outer_array[0].middle_array[0].inner_array[0].inner_object"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[0].inner_object.seven` is required', 'reference' => "outer_array[0].middle_array[0].inner_array[0].inner_object.seven"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[1].five` is required',               'reference' => "outer_array[0].middle_array[0].inner_array[1].five"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[1].six` is required',                'reference' => "outer_array[0].middle_array[0].inner_array[1].six"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[1].inner_object` is required',       'reference' => "outer_array[0].middle_array[0].inner_array[1].inner_object"},
        {'code' => 'generic.required_field_missing', 'message' => 'Field `outer_array[0].middle_array[0].inner_array[1].inner_object.seven` is required', 'reference' => "outer_array[0].middle_array[0].inner_array[1].inner_object.seven"}
      ])

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => [
              {
                :three => 'here',
                :four  => 'here',
                :inner_array => [
                  {
                    :five => 'here',
                    :six => 'here',
                    :inner_object => {
                      :seven => 'here'
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
      data = Hoodoo::Utilities.stringify(data)
      expect(NastyNesting.validate(data, false).errors).to eq([])
    end

    it 'should validate resource fields for language correctly' do
      expect(Internationalised.validate({}, true).errors.count).to eq(4)
      expect(NotInternationalised.validate({}, true).errors.count).to eq(3)

      # Check schema redefinition for the required language field is working
      # OK by repeating the above two expectations.
      #
      expect(Internationalised.validate({}, true).errors.count).to eq(4)
      expect(NotInternationalised.validate({}, true).errors.count).to eq(3)
    end

    it 'should validate an internationalised hash (1)' do
      result = HashGainsInternationalisation.validate({}, true)
      expect(result.errors.count).to eq(4) # I.e. missing ID, created_at, kind *and language*.
    end

    it 'should validate an internationalised hash (2)' do
      result = HashGainsInternationalisation2.validate({}, true)
      expect(result.errors.count).to eq(4) # I.e. missing ID, created_at, kind *and language*.
    end

    it 'should validate contents correctly (1)' do
      data   = { 'inter' => { 'a' => { 'hello' => 'hellotext' }, 'b' => { 'hello' => 'morehellotext' } } }
      result = HashGainsInternationalisation.validate( data, false ) # false => Type fields only, ignore common fields
      expect(result.errors.count).to eq(0)
    end

    it 'should validate contents correctly (2)' do
      data   = { 'inter' => { 'one' => { 'foo' => 'bar' }, 'two' => { 'hello' => 'twohellotext' } } }
      result = HashGainsInternationalisation2.validate( data, false ) # true => Type fields only, ignore common fields
      expect(result.errors.count).to eq(0)
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

    it 'should render correctly as a type without a UUID' do
      data = Hoodoo::Utilities.stringify({
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1' }
          ]
        }
      })

      expect(Hoodoo::Data::Resources::World.render(data)).to eq({
        'errors_id' => data['errors_id'],
        'test_tags' => 'foo,bar,baz',
        'test_object' => {
          'nested_object' => {
            'name' => 'Some name',
            'obj_suffix' => '!'
          },
          'test_array' => [
            { 'name' => 'Some name 0', 'ary_suffix' => '00' },
            { 'name' => 'Some name 1' }
          ]
        }
      })
    end

    it 'should render correctly as a resource with a UUID' do
      data = Hoodoo::Utilities.stringify({
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1' }
          ]
        }
      })

      uuid = Hoodoo::UUID.generate
      time = Time.now

      expect(Hoodoo::Data::Resources::World.render(
        data,
        uuid,
        time,
        'en-gb'
      )).to eq({
        'id' => uuid,
        'kind' => 'World',
        'created_at' => time.utc.iso8601,
        'language' => 'en-gb',
        'errors_id' => data['errors_id'],
        'test_tags' => 'foo,bar,baz',
        'test_object' => {
          'nested_object' => {
            'name' => 'Some name',
            'obj_suffix' => '!'
          },
          'test_array' => [
            { 'name' => 'Some name 0', 'ary_suffix' => '00' },
            { 'name' => 'Some name 1' }
          ]
        }
      })
    end

    it 'should complain about resources with no creation date' do
      data = {
        :errors_id => Hoodoo::UUID.generate,
        :test_tags => 'foo,bar,baz',
        :test_object => {
          :nested_object => {
            :name => 'Some name',
            :obj_suffix => '!'
          },
          :test_array => [
            { :name => 'Some name 0', :ary_suffix => '00' },
            { :name => 'Some name 1' }
          ]
        }
      }

      data = Hoodoo::Utilities.stringify(data)
      uuid = Hoodoo::UUID.generate

      expect {
        Hoodoo::Data::Resources::World.render(
          data,
          uuid,
          nil,
          'en-gb'
        )
      }.to raise_error(RuntimeError, "Can't render a Resource with a nil 'created_at'")
    end

    it 'should render hash contents correctly (1)' do
      data   = { 'inter' => { 'a' => { 'hello' => 'hellotext' }, 'b' => { 'hello' => 'morehellotext' } } }
      result = HashGainsInternationalisation.render( data )
      expect(result).to eq(data)
    end

    it 'should render hash contents correctly (2)' do
      data   = { 'inter' => { 'one' => { 'foo' => 'bar' }, 'two' => { 'hello' => 'twohellotext' } } }
      result = HashGainsInternationalisation2.render( data )
      expect(result).to eq(data)
    end

    it 'should render hash contents correctly (3)' do
      data   = { 'inter' => { 'one' => { 'foo' => 'bar' }, 'two' => { 'hello' => 'twohellotext' } } }
      result = HashGainsInternationalisation.render( data ) # Note not the '2' variant of the class
      expect(result).to eq({ 'inter' => { 'one' => {}, 'two' => { 'hello' => 'twohellotext' } } })
    end
  end
end
