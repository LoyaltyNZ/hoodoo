require 'spec_helper'

describe Hoodoo::Presenters::Array do

  before do
    @inst = Hoodoo::Presenters::Array.new('one',:required => false)

    class TestPresenterArray < Hoodoo::Presenters::Base

      schema do
        array :an_array, :required => true do
          integer :an_integer
          datetime :a_datetime
        end
        # Intentional mix of strings and symbols in default array
        array :a_default_array, :default => [ { :an_integer => 42 }, { 'some_array_text' => 'hello' } ] do
          integer :an_integer
          text :some_array_text
        end
        array :an_array_with_entry_defaults do
          integer :an_integer, :default => 42
          datetime :a_datetime
        end
        array :an_array_of_anything
        enum :an_enum, :from => [ :one, 'two', 3 ]
        text :some_text
      end

    end
  end

  ############################################################################

  describe '#validate' do
    it 'should return [] when valid array' do
      expect(@inst.validate([]).errors).to eq([])
    end

    it 'should return correct error when data is not a array' do
      errors = @inst.validate('asckn')

      err = [  {'code'=>"generic.invalid_array", 'message'=>"Field `one` is an invalid array", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should return correct error with non array types' do
      err = [  {'code'=>"generic.invalid_array", 'message'=>"Field `one` is an invalid array", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534).errors).to eq(err)
      expect(@inst.validate(2123.23).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
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

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_array", 'message'=>"Field `ordinary.one` is an invalid array", 'reference'=>"ordinary.one"}
      ])
    end

    it 'should raise error if required but omitted' do
      data = {
      }

      errors = TestPresenterArray.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `an_array` is required", 'reference'=>"an_array"},
      ])

    end

    it 'should not insist on non-required entry fields in a required array' do
      data = {
        'an_array' => [
          {},
          { 'an_integer' => 2 },
          { 'a_datetime' => Time.now.iso8601 }
        ]
      }

      errors = TestPresenterArray.validate(data)
      expect(errors.errors).to eq([])
    end

    it 'should validate all entry fields' do
      data = {
        'an_array' => [
          {},
          { 'an_integer' => 'invalid' },
          { 'a_datetime' => 'invalid' }
        ]
      }

      errors = TestPresenterArray.validate(data)
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_integer", 'message'=>"Field `an_array[1].an_integer` is an invalid integer", 'reference'=>"an_array[1].an_integer"},
        {'code'=>"generic.invalid_datetime", 'message'=>"Field `an_array[2].a_datetime` is an invalid ISO8601 datetime", 'reference'=>"an_array[2].a_datetime"},
      ])
    end

    it 'should let anything be placed in an array with no schema properties' do
      data = {
        'an_array' => [],
        'an_array_of_anything' => [
          'one',
          2,
          true,
          { :hello => :world }
        ]
      }

      errors = TestPresenterArray.validate(data)
      expect(errors.errors).to eq([])
    end
  end

  ############################################################################

  describe '#render' do
    it 'renders correctly with whole-array default (1)' do
      data = nil
      expect(TestPresenterArray.render(data)).to eq({
        'a_default_array' => [ { 'an_integer' => 42 }, { 'some_array_text' => 'hello' } ]
      })
    end

    it 'renders correctly with whole-array default (2)' do
      data = {}
      expect(TestPresenterArray.render(data)).to eq({
        'a_default_array' => [ { 'an_integer' => 42 }, { 'some_array_text' => 'hello' } ]
      })
    end

    it 'does not overwrite explicit nil for array with default' do
      data = {
        'a_default_array' => nil
      }
      expect(TestPresenterArray.render(data)).to eq(data)
    end

    it 'does not overwrite explicit empty array for array with default' do
      data = {
        'a_default_array' => []
      }
      expect(TestPresenterArray.render(data)).to eq(data)
    end

    it 'treats invalid types as nil' do
      data = {
        'a_default_array' => 'not an array'
      }
      expect(TestPresenterArray.render(data)).to eq({
        'a_default_array' => nil
      })
    end

    it 'should render correctly with whole-array default' do
      time = Time.now.iso8601
      data = {
        'an_enum' => 'one',
        'an_array' => [
          {},
          { 'an_integer' => 2 },
          { 'a_datetime' => time }
        ]
      }

      expect(TestPresenterArray.render(data)).to eq({
        'an_array' => [
          {
          },
          {
            'an_integer' => 2,
          },
          {
            'a_datetime' => time
          }
        ],
        'a_default_array' => [ { 'an_integer' => 42 }, { 'some_array_text' => 'hello' } ],
        'an_enum' => "one"
      })
    end

    it 'should render correctly with per-entry defaults' do
      time = Time.now.iso8601
      data = {
        'an_enum' => 'one',
        'an_array' => [
          { 'an_integer' => 2 }
        ],
        'an_array_with_entry_defaults' => [
          nil,
          {},
          { 'an_integer' => 0 },
          { 'an_integer' => 23 },
          { 'a_datetime' => time }
        ]
      }

      expect(TestPresenterArray.render(data)).to eq({
        'an_array' => [
          { 'an_integer' => 2 }
        ],
        'a_default_array' => [ { 'an_integer' => 42 }, { 'some_array_text' => 'hello' } ],
        'an_array_with_entry_defaults' => [
          nil, # Because explict-input-nil-means-nil-outputm always
          { 'an_integer' => 42 }, # Because empty objects always get field defaults, just as at the root level
          { 'an_integer' => 0 },
          { 'an_integer' => 23 },
          { 'an_integer' => 42, 'a_datetime' => time },
        ],
        'an_enum' => "one"
      })
    end

    it 'should render any entries in an array with no schema properties' do
      data = {
        'an_array' => [],
        'an_array_of_anything' => [
          'one',
          2,
          true,
          { :hello => :world }
        ]
      }

      expect(TestPresenterArray.render(data)).to eq({
        'an_array' => [],
        'a_default_array' => [ { 'an_integer' => 42 }, { 'some_array_text' => 'hello' } ],
        'an_array_of_anything' => [
          'one',
          2,
          true,
          { :hello => :world }
        ]
      })
    end
  end
  class TestPresenterTypedArray < Hoodoo::Presenters::Base
    schema do
      array :array,     :type => :array
      array :boolean,   :type => :boolean
      array :date,      :type => :date
      array :date_time, :type => :date_time
      array :decimal,   :type => :decimal,   :field_precision => 2
      array :enum,      :type => :enum,      :field_from      => [ :one, :two, :three ]
      array :float,     :type => :float
      array :integer,   :type => :integer
      array :string,    :type => :string,    :field_length    => 4
      array :tags,      :type => :tags
      array :text,      :type => :text
      array :uuid,      :type => :uuid
      array :field
    end
  end

  ############################################################################

  ARRAY_DATA = {
    'array'     => { :valid => [ [ 2, 3, 4 ]             ], :invalid => [ 4, { :one => 1 }                 ] },
    'boolean'   => { :valid => [ true                    ], :invalid => [ 4.51, 'false'                    ] },
    'date'      => { :valid => [ Date.today.iso8601      ], :invalid => [ Date.today, '23rd January 2041'  ] },
    'date_time' => { :valid => [ DateTime.now.iso8601    ], :invalid => [ DateTime.now, '2017-01-27 12:00' ] },
    'decimal'   => { :valid => [ BigDecimal.new(4.51, 2) ], :invalid => [ 4.51, '4.51'                     ] },
    'enum'      => { :valid => [ 'one'                   ], :invalid => [ 'One', 1                         ] },
    'float'     => { :valid => [ 4.51                    ], :invalid => [ BigDecimal.new(4.51, 2), '4.51'  ] },
    'integer'   => { :valid => [ 4                       ], :invalid => [ '4'                              ] },
    'string'    => { :valid => [ 'four'                  ], :invalid => [ 'toolong', 4, true               ] },
    'tags'      => { :valid => [ 'tag_a,tag_b,tag_c'     ], :invalid => [ 4, true                          ] },
    'text'      => { :valid => [ 'hello world'           ], :invalid => [ 4, true                          ] },
    'uuid'      => { :valid => [ Hoodoo::UUID.generate() ], :invalid => [ '123456', 4, true                ] },
    'field'     => { :valid => [ 4, '4', { :one => 1 }   ], :invalid => [                                  ] }
  }

  ARRAY_DATA.each do | field, values |
    context '#render' do
      values[ :valid ].each_with_index do | value, index |
        it "renders correctly for '#{ field }' (#{ index + 1 })" do
          data = { field => [ value, value, value ] }
          expect( TestPresenterTypedArray.render( data ) ).to eq( data )
        end
      end
    end

    context '#validate' do
      values[ :valid ].each_with_index do | value, index |
        it "accepts a valid value for '#{ field }' (#{ index + 1 })" do
          data = { field => [ value, value, value ] }
          expect( TestPresenterTypedArray.validate( data ).errors.size ).to eql( 0 )
        end
      end

      values[ :invalid ].each_with_index do | value, index |
        it "rejects an invalid value for '#{ field }' (#{ index + 1 })" do
          data = { field => [ value, value, value ] }
          expect( TestPresenterTypedArray.validate( data ).errors.size ).to eql( 3 )
        end
      end
    end
  end

end
