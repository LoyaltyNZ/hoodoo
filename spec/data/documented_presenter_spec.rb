require "spec_helper"

describe '#schema' do

  # Just in case someone's deliberately excluding other source files to
  # check on code coverage...
  #
  module ApiTools
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

  class NastyNesting < ApiTools::Data::DocumentedPresenter
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

  class Internationalised < ApiTools::Data::DocumentedPresenter
    schema do
      internationalised
    end
  end

  class NotInternationalised < ApiTools::Data::DocumentedPresenter
    schema do
    end
  end

  # For testing hashes with type references

  class Internationalised2 < ApiTools::Data::DocumentedPresenter
    schema do
      internationalised
      text :hello
    end
  end

  class HashGainsInternationalisation < ApiTools::Data::DocumentedPresenter
    schema do
      hash :inter do
        keys do
          type :Internationalised2
        end
      end
    end
  end

  class HashGainsInternationalisation2 < ApiTools::Data::DocumentedPresenter
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

  describe '#validate' do
    it 'should have schema defined properly' do

      schema = ApiTools::Data::Types::Hello.get_schema

      expect(ApiTools::Data::Types::Hello.is_internationalised?()).to eq(true)
      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(1)
      expect(schema.properties['name']).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties['name'].required).to eq(true)

      schema = ApiTools::Data::Resources::World.get_schema

      expect(ApiTools::Data::Resources::World.is_internationalised?()).to eq(true)
      expect(schema.is_internationalised?()).to eq(true)
      expect(schema.properties.count).to eq(3)
      expect(schema.properties['errors_id']).to be_a(ApiTools::Presenters::UUID)
      expect(schema.properties['errors_id'].required).to eq(false)
      expect(schema.properties['errors_id'].resource).to eq(:Errors)
      expect(schema.properties['test_tags']).to be_a(ApiTools::Presenters::Tags)
      expect(schema.properties['test_tags'].required).to eq(false)
      expect(schema.properties['test_object']).to be_a(ApiTools::Data::DocumentedObject)
      expect(schema.properties['test_object'].required).to eq(true)
      expect(schema.properties['test_object'].properties['nested_object']).to be_a(ApiTools::Data::DocumentedObject)
      expect(schema.properties['test_object'].properties['nested_object'].required).to eq(false)
      expect(schema.properties['test_object'].properties['nested_object'].properties['name']).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix']).to be_a(ApiTools::Presenters::String)
      expect(schema.properties['test_object'].properties['nested_object'].properties['obj_suffix'].length).to eq(1)
      expect(schema.properties['test_object'].properties['test_array']).to be_a(ApiTools::Data::DocumentedArray)
      expect(schema.properties['test_object'].properties['test_array'].required).to eq(false)
      expect(schema.properties['test_object'].properties['test_array'].properties['name']).to be_a(ApiTools::Presenters::Text)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix']).to be_a(ApiTools::Presenters::String)
      expect(schema.properties['test_object'].properties['test_array'].properties['ary_suffix'].length).to eq(2)
    end

    it 'should return no errors with valid data for type only' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      expect(ApiTools::Data::Resources::World.validate(data, true).errors).to eq([])
    end

    it 'should return no errors with valid data for resource' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      rendered = ApiTools::Data::Resources::World.render(
        data,
        ApiTools::UUID.generate,
        Time.now
      )

      expect(ApiTools::Data::Resources::World.validate(rendered).errors).to eq([])
    end

    it 'should return correct errors invalid data' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      expect(ApiTools::Data::Resources::World.validate(data, true).errors).to eq([
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
      expect(NastyNesting.validate(data, true).errors).to eq([
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
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([])

      # The outer array is present and has two entries that omit required
      # fields, so we expect errors for all of them.

      data = {
        :outer_array => [{}, {}]
      }
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([
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
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([])

      data = {
        :outer_array => [
          {
            :one => 'here',
            :two => 'here',
            :middle_array => [{},{}]
          }
        ]
      }
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([
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
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([])

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
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([
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
      data = ApiTools::Utilities.stringify(data)
      expect(NastyNesting.validate(data, true).errors).to eq([])
    end

    it 'should validate resource fields for language correctly' do
      expect(Internationalised.validate({}).errors.count).to eq(4)
      expect(NotInternationalised.validate({}).errors.count).to eq(3)

      # Check schema redefinition for the required language field is working
      # OK by repeating the above two expectations.
      #
      expect(Internationalised.validate({}).errors.count).to eq(4)
      expect(NotInternationalised.validate({}).errors.count).to eq(3)
    end

    it 'should validate an internationalised hash (1)' do
      result = HashGainsInternationalisation.validate({})
      expect(result.errors.count).to eq(4) # I.e. missing ID, created_at, kind *and language*.
    end

    it 'should validate an internationalised hash (2)' do
      result = HashGainsInternationalisation2.validate({})
      expect(result.errors.count).to eq(4) # I.e. missing ID, created_at, kind *and language*.
    end

    it 'should validate contents correctly (1)' do
      data   = { 'inter' => { 'a' => { 'hello' => 'hellotext' }, 'b' => { 'hello' => 'morehellotext' } } }
      result = HashGainsInternationalisation.validate( data, true ) # true => Type fields only, ignore common fields
      expect(result.errors.count).to eq(0)
    end

    it 'should validate contents correctly (2)' do
      data   = { 'inter' => { 'one' => { 'foo' => 'bar' }, 'two' => { 'hello' => 'twohellotext' } } }
      result = HashGainsInternationalisation2.validate( data, true ) # true => Type fields only, ignore common fields
      expect(result.errors.count).to eq(0)
    end
  end

  describe '#render' do
    it 'should render correctly as a type without a UUID' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      expect(ApiTools::Data::Resources::World.render(data)).to eq({
        'errors_id' => data['errors_id'],
        'test_tags' => 'foo,bar,baz',
        'test_object' => {
          'nested_object' => {
            'name' => 'Some name',
            'obj_suffix' => '!'
          },
          'test_array' => [
            { 'name' => 'Some name 0', 'ary_suffix' => '00' },
            { 'name' => 'Some name 1', 'ary_suffix' => nil }
          ]
        }
      })
    end

    it 'should render correctly as a resource with a UUID' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      uuid = ApiTools::UUID.generate
      time = Time.now

      expect(ApiTools::Data::Resources::World.render(
        data,
        uuid,
        time,
        'en-gb'
      )).to eq({
        'id' => uuid,
        'kind' => 'World',
        'created_at' => time.iso8601,
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
            { 'name' => 'Some name 1', 'ary_suffix' => nil }
          ]
        }
      })
    end

    it 'should complain about resources with no creation date' do
      data = {
        :errors_id => ApiTools::UUID.generate,
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

      data = ApiTools::Utilities.stringify(data)
      uuid = ApiTools::UUID.generate

      expect {
        ApiTools::Data::Resources::World.render(
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
      expect(result).to eq({ 'inter' => { 'one' => { 'hello' => nil }, 'two' => { 'hello' => 'twohellotext' } } })
    end
  end

  describe '#parse' do
    it 'should parse correctly' do
      data = {
        'errors_id' => ApiTools::UUID.generate,
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
      }

      # We've defined no mappings here - they're tested elsewhere - so parsing
      # is just "take fields and put them back where they came from".

      expect(ApiTools::Data::Resources::World.parse(data)).to eq(data)
    end
  end
end
