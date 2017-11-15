require 'spec_helper'

describe Hoodoo::Presenters::Hash do

  context 'exceptions' do
    it 'should complain about #key then #keys' do
      expect {
        class TestHashKeyKeysException < Hoodoo::Presenters::Base
          schema do
            hash :foo do
              key :one
              keys :length => 4
            end
          end
        end
      }.to raise_error( RuntimeError )
    end

    it 'should complain about #keys then #key' do
      expect {
        class TestHashKeysKeyException < Hoodoo::Presenters::Base
          schema do
            hash :foo do
              keys :length => 4
              key :one
            end
          end
        end
      }.to raise_error( RuntimeError )
    end

    it 'should complain about #keys twice' do
      expect {
        class TestHashKeysKeysException < Hoodoo::Presenters::Base
          schema do
            hash :foo do
              keys :length => 4
              keys :length => 4
            end
          end
        end
      }.to raise_error( RuntimeError )
    end
  end

  ############################################################################

  class TestHashNoKeysPresenter < Hoodoo::Presenters::Base
    schema do
      hash :specific
    end
  end

  class TestHashNoKeysPresenterRequired < Hoodoo::Presenters::Base
    schema do
      hash :specific_required, :required => true
    end
  end

  ############################################################################

  context 'no keys' do
    context '#validate' do
      it 'should return [] when valid object' do
        data = { 'specific' => { 'hello' => 'there' } }
        expect( TestHashNoKeysPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct error when data is not an object' do
        data   = { 'specific' => 'hello' }
        errors = [ {
          'code'      => 'generic.invalid_hash',
          'message'   => 'Field `specific` is an invalid hash',
          'reference' => 'specific'
        } ]

        expect( TestHashNoKeysPresenter.validate( data ).errors ).to eq( errors )
      end

      it 'should not return error when not required and absent' do
        data = { 'foo' => 'bar' }
        expect( TestHashNoKeysPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return error when required and absent' do
        data   = { 'foo' => 'bar' }
        errors = [ {
          'code'      => 'generic.required_field_missing',
          'message'   => 'Field `specific_required` is required',
          'reference' => 'specific_required'
        } ]

        expect( TestHashNoKeysPresenterRequired.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should render correctly' do
        data   = { 'specific' => { 'hello' => 'there' } }
        result = TestHashNoKeysPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should render correctly when described hash is not required and absent' do
        data   = { 'foo' => 'bar' }
        result = TestHashNoKeysPresenter.render( data )

        expect( result ).to eq({})
      end
    end
  end

  ############################################################################

  class TestHashSpecificKeyPresenter < Hoodoo::Presenters::Base
    schema do
      hash :specific do
        key :one
        key :two do
          string :foo, :length => 10
          text :bar, :required => true
        end
        key :three do
          integer :int
          uuid :id
        end
      end
    end
  end

  ############################################################################

  context 'specific keys' do
    context '#validate' do
      it 'should return [] when valid object (1)' do
        data = { 'specific' => { 'one' => 'anything' } }
        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (2)' do
        data = { 'specific' => { 'two' => { 'foo' => 'foov', 'bar' => 'barv' } } }
        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (3)' do
        data = { 'specific' => { 'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } } }
        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (4)' do
        data = { 'specific' => { 'one' => 'anything',
                                 'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                                 'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } } }

        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct error when data is not an object' do
        data   = { 'specific' => 'hello' }
        errors = [ {
          'code'      => 'generic.invalid_hash',
          'message'   => 'Field `specific` is an invalid hash',
          'reference' => 'specific'
        } ]

        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct error when unexpected keys are present' do
        data = { 'specific' => { 'hi' => 'there',
                                 'foo' => { 'bar' => 'baz' },
                                 'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } } }
        errors = [ {
          'code'      => 'generic.invalid_hash',
          'message'   => 'Field `specific` is an invalid hash due to unrecognised keys `hi, foo`',
          'reference' => 'specific'
        } ]

        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct errors when value formats are wrong or required values are omitted' do
        data = { 'specific' => { 'three' => { 'int' => 'not an int', 'id' => 'not an id' }, 'two' => {} } }

        errors = [
          {
            'code'      => 'generic.invalid_integer',
            'message'   => 'Field `specific.three.int` is an invalid integer',
            'reference' => 'specific.three.int'
          },
          {
            'code'      => 'generic.invalid_uuid',
            'message'   => 'Field `specific.three.id` is an invalid UUID',
            'reference' => 'specific.three.id'
          },
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `specific.two.bar` is required',
            'reference' => 'specific.two.bar'
          },
        ]

        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should render correctly (1)' do
        data   = { 'specific' => { 'one' => 'anything' } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should render correctly (2)' do
        data   = { 'specific' => { 'two' => { 'foo' => 'foov', 'bar' => 'barv' } } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should render correctly (3)' do
        data   = { 'specific' => { 'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should render correctly (4)' do
        data   = { 'specific' => { 'one' => 'anything',
                                   'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                                   'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should ignore unspecified entries' do
        inner = { 'one' => 'anything',
                  'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                  'three' => { 'int' => 23, 'id' => Hoodoo::UUID.generate() } }

        valid = { 'specific' => inner.dup }
        data  = { 'specific' => inner.dup }

        data[ 'generic' ] = 'hello'
        data[ 'specific' ][ 'random' ] = 23

        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( valid )
      end
    end
  end

  ############################################################################

  class TestNestedHashSpecificKeyPresenter < Hoodoo::Presenters::Base
    schema do
      object :obj do
        text :obj_text
        hash :specific do
          key :two do
            string :two_key_string, :length => 10
            hash :two_key_hash do
              key :inner
              key :inner_2 do
                string :inner_2_string, :length => 4
              end
            end
          end
        end
      end
    end
  end

  ############################################################################

  context 'nested specific keys' do
    context '#validate' do
      it 'should return [] when valid object (1)' do
        data = { 'obj' => { 'specific' => {} } }
        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (2)' do
        data = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'two' => {} } } }
        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return error with incorrect nested keys (1)' do
        data   = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'three' => {} } } }
        errors = [
          {
            'code'      => 'generic.invalid_hash',
            'message'   => 'Field `obj.specific` is an invalid hash due to unrecognised keys `three`',
            'reference' => 'obj.specific'
          }
        ]

        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end

      it 'should return [] when valid object (3)' do
        data = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'two' => { 'two_key_hash' => {} } } } }
        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (4)' do
        data = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'two' => { 'two_key_hash' => { 'inner' => true } } } } }
        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return error with incorrect nested keys (2)' do
        data = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'two' => { 'two_key_hash' => { 'madeup' => true } } } } }
        errors = [
          {
            'code'      => 'generic.invalid_hash',
            'message'   => 'Field `obj.specific.two.two_key_hash` is an invalid hash due to unrecognised keys `madeup`',
            'reference' => 'obj.specific.two.two_key_hash'
          }
        ]

        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end

      it 'should return error with incorrect nested values' do
        data = { 'obj' => { 'obj_text' => 'hello', 'specific' => { 'two' => { 'two_key_hash' => { 'inner_2' => { 'inner_2_string' => 'too-long-for-here' } } } } } }
        errors = [
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `obj.specific.two.two_key_hash.inner_2.inner_2_string` is longer than maximum length `4`',
            'reference' => 'obj.specific.two.two_key_hash.inner_2.inner_2_string'
          }
        ]

        expect( TestNestedHashSpecificKeyPresenter.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should render complex entity correctly' do
        valid  = { 'obj' => { 'obj_text' => 'hello',                   'specific' => { 'two' => { 'two_key_hash' => { 'inner' => 42, 'inner_2' => { 'inner_2_string' => 'ok' } } } } } }
        data   = { 'obj' => { 'obj_text' => 'hello', 'random' => true, 'specific' => { 'two' => { 'two_key_hash' => { 'inner' => 42, 'inner_2' => { 'inner_2_string' => 'ok' } } } } } }

        result = TestNestedHashSpecificKeyPresenter.render( data )
        expect( result ).to eq( valid )
      end
    end
  end

  ############################################################################

  class TestHashSpecificKeyPresenterWithRequirements < Hoodoo::Presenters::Base
    schema do
      hash :specific do
        key :one, :required => true
        key :two, :required => true do
          string :foo, :length => 10
          text :bar, :required => true
        end
      end
    end
  end

  ############################################################################

  context 'specific keys with requirements' do
    context '#validate' do
      it 'should return correct errors when keys are omitted (1)' do
        data   = { 'specific' => {} }
        errors = [
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `specific.one` is required',
            'reference' => 'specific.one'
          },
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `specific.two` is required',
            'reference' => 'specific.two'
          },
        ]

        expect( TestHashSpecificKeyPresenterWithRequirements.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct errors when keys are omitted (2)' do
        data   = { 'specific' => { 'two' => { 'foo' => 'foov' } } }
        errors = [
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `specific.two.bar` is required',
            'reference' => 'specific.two.bar'
          },
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `specific.one` is required',
            'reference' => 'specific.one'
          }
        ]

        expect( TestHashSpecificKeyPresenterWithRequirements.validate( data ).errors ).to eq( errors )
      end
    end
  end

  ############################################################################

  class TestHashSpecificKeyPresenterWithDefaults < Hoodoo::Presenters::Base
    schema do
      hash :specific_defaults, :default => { 'one' => 'anything', 'two' => { 'foo' => 'valid' }, 'ignoreme' => 'invalid' } do
        key :one, :default => { 'foo' => { 'bar' => 'baz' } }
        key :two do
          string :foo, :length => 10
          text :bar, :default => 'this is the text field for "bar"'
          integer :baz, :default => 42
        end
        key :three, :default => { 'bar' => 'for_key_three' } do
          string :foo, :length => 10
          text :bar, :default => 'this is the text field for "bar"'
          integer :baz, :default => 42
        end
      end
    end
  end

  class TestHashSpecificKeyPresenterWithDefaultsExceptHash < Hoodoo::Presenters::Base
    schema do
      hash :specific_defaults do
        key :one, :default => { 'foo' => { 'bar' => 'baz' } }
        key :two do
          string :foo, :length => 10
          text :bar, :default => 'this is the text field for "bar"'
          integer :baz, :default => 42
        end
      end
    end
  end

  ############################################################################

  context 'specific keys with defaults' do
    context '#render' do

      # The hash itself has a default set, so if the hash key is omitted we
      # expect to get the canned default hash instead.
      #
      it 'should render with correct default for whole hash (1)' do
        result = TestHashSpecificKeyPresenterWithDefaults.render( {} )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => 'anything',
            'two' => { 'foo' => 'valid', 'bar' => 'this is the text field for "bar"', 'baz' => 42 },
            'three' => { 'bar' => 'for_key_three', 'baz' => 42 }
          }
        })
      end

      # Should behave the same with 'nil'.
      #
      it 'should render with correct default for whole hash (2)' do
        result = TestHashSpecificKeyPresenterWithDefaults.render( nil )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => 'anything',
            'two' => { 'foo' => 'valid', 'bar' => 'this is the text field for "bar"', 'baz' => 42 },
            'three' => { 'bar' => 'for_key_three', 'baz' => 42 }
          }
        })
      end

      # Empty objects gain default fields, just like at the root level;
      # and key-level defaults (one is specified for key 'three') also end
      # up with field-level defaults merged (almost by accident, but it
      # makes sense to do so) - integer 'baz' has a default value of 42 as
      # a field-level default.
      #
      it 'renders an explicit empty hash with default fields' do
        data   = { 'specific_defaults' => {} }
        result = TestHashSpecificKeyPresenterWithDefaults.render( data )
        expect( result ).to eq({
          'specific_defaults' => {
            'one' => { 'foo' => { 'bar' => 'baz' } },
            'three' => { 'bar' => 'for_key_three', 'baz' => 42 }
          }
        })
      end

      # ...but explicit nil means nil.
      #
      it 'renders an explicit nil' do
        data   = { 'specific_defaults' => nil }
        result = TestHashSpecificKeyPresenterWithDefaults.render( data )
        expect( result ).to eq(data)
      end

      # One of the hash's specific keys has a defined block with some default
      # values, so if we specify an empty hash for that key, we expect it to
      # be filled in with defaults.
      #
      it 'should render with correct defaults for hash value keys' do
        data   = { 'specific_defaults' => { 'two' => {} } }
        result = TestHashSpecificKeyPresenterWithDefaults.render( data )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => { 'foo' => { 'bar' => 'baz' } },
            'two' => {
              'bar' => 'this is the text field for "bar"',
              'baz' => 42
            },
            'three' => { 'bar' => 'for_key_three', 'baz' => 42 }
          }
        })
      end

      # Take away the hash-level full default value; we expect an omitted hash
      # to be rendered with default contents.
      #
      it 'should render with correct default for keys when hash itself has no default (1)' do
        result = TestHashSpecificKeyPresenterWithDefaultsExceptHash.render( {} )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => { 'foo' => { 'bar' => 'baz' } }
          }
        })
      end

      # Should behave the same with 'nil'.
      #
      it 'should render with correct default for keys when hash itself has no default (2)' do
        result = TestHashSpecificKeyPresenterWithDefaultsExceptHash.render( nil )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => { 'foo' => { 'bar' => 'baz' } }
          }
        })
      end

      # We also expect the same result if an empty hash is provided, as with the
      # case where the hash itself had a default value.
      #
      it 'should render with correct defaults for hash keys (3)' do
        data   = { 'specific_defaults' => {} }
        result = TestHashSpecificKeyPresenterWithDefaultsExceptHash.render( data )

        expect( result ).to eq({
          'specific_defaults' => {
            'one' => { 'foo' => { 'bar' => 'baz' } }
          }
        })
      end

      # Once more, explicit nil means nil.
      #
      it 'should render with correct defaults for hash keys (4)' do
        data   = { 'specific_defaults' => nil }
        result = TestHashSpecificKeyPresenterWithDefaultsExceptHash.render( data )

        expect( result ).to eq(data)
      end
    end
  end

  ############################################################################

  class TestHashSpecificKeyTypes < Hoodoo::Presenters::Base
    schema do
      hash :specific_key_types, :default => { 'array' => [ 1, 2, 3 ], 'float' => 0.5 } do
        key :array,     :type => :array
        key :boolean,   :type => :boolean
        key :date,      :type => :date
        key :date_time, :type => :date_time
        key :decimal,   :type => :decimal,   :field_precision => 2
        key :enum,      :type => :enum,      :field_from      => [ :one, :two, :three ]
        key :float,     :type => :float
        key :integer,   :type => :integer,   :field_default   => 1              # ":field_default" (sic.)
        key :string,    :type => :string,    :field_length    => 4
        key :tags,      :type => :tags,      :default         => 'default,tags' # ":default" (sic.)
        key :text,      :type => :text
        key :uuid,      :type => :uuid
        key :field
      end
    end
  end

  ############################################################################

  context 'specific keys with elementary types and defaults' do
    KEY_DATA = {
      'array'     => { :valid => [ [ 2, 3, 4 ]             ], :invalid => [ 4, { :one => 1 }                 ] },
      'boolean'   => { :valid => [ true                    ], :invalid => [ 4.51, 'false'                    ] },
      'date'      => { :valid => [ Date.today.iso8601      ], :invalid => [ Date.today, '23rd January 2041'  ] },
      'date_time' => { :valid => [ DateTime.now.iso8601    ], :invalid => [ DateTime.now, '2017-01-27 12:00' ] },
      'decimal'   => { :valid => [ '4.51'                  ], :invalid => [ 4.51, BigDecimal.new( '4.51' )   ] },
      'enum'      => { :valid => [ 'one'                   ], :invalid => [ 'One', 1                         ] },
      'float'     => { :valid => [ 4.51                    ], :invalid => [ BigDecimal.new(4.51, 2), '4.51'  ] },
      'integer'   => { :valid => [ 4                       ], :invalid => [ '4'                              ] },
      'string'    => { :valid => [ 'four'                  ], :invalid => [ 'toolong', 4, true               ] },
      'tags'      => { :valid => [ 'tag_a,tag_b,tag_c'     ], :invalid => [ 4, true                          ] },
      'text'      => { :valid => [ 'hello world'           ], :invalid => [ 4, true                          ] },
      'uuid'      => { :valid => [ Hoodoo::UUID.generate() ], :invalid => [ '123456', 4, true                ] },
      'field'     => { :valid => [ 4, '4', { :one => 1 }   ], :invalid => [                                  ] }
    }

    context '#render' do
      it 'renders correctly with whole-hash defaults' do
        expected_data = { 'specific_key_types' => { 'array'   => [ 1, 2, 3 ],
                                                    'float'   => 0.5,
                                                    'integer' => 1,
                                                    'tags'    => 'default,tags' } }

        expect( TestHashSpecificKeyTypes.render( {}  ) ).to eq( expected_data )
        expect( TestHashSpecificKeyTypes.render( nil ) ).to eq( expected_data )
      end
    end

    KEY_DATA.each do | field, values |
      context '#render' do
        values[ :valid ].each_with_index do | value, index |
          it "renders correctly for '#{ field }' (#{ index + 1 })" do

            # Start with the defaults we expect given KEY_DATA definitions
            # above then merge in the under-test field value. Only the inner
            # field defaults are carried because we are passing a non-empty
            # Hash in the top level for rendering, which overrides therefore
            # the top-level Hash default.
            #
            expected_data = { 'specific_key_types' => { 'integer' => 1,
                                                        'tags'    => 'default,tags' } }

            data = { 'specific_key_types' => { field => value } }
            expected_data = Hoodoo::Utilities.deep_merge_into( expected_data, data )

            expect( TestHashSpecificKeyTypes.render( data ) ).to eq( expected_data )
          end
        end
      end

      context '#validate' do
        values[ :valid ].each_with_index do | value, index |
          it "accepts a valid value for '#{ field }' (#{ index + 1 })" do
            data = { 'specific_key_types' => { field => value } }
            expect( TestHashSpecificKeyTypes.validate( data ).errors.size ).to( eql( 0 ) )
          end
        end

        values[ :invalid ].each_with_index do | value, index |
          it "rejects an invalid value for '#{ field }' (#{ index + 1 })" do
            data = { 'specific_key_types' => { field => value } }
            expect( TestHashSpecificKeyTypes.validate( data ).errors.size ).to( eql( 1 ) )
          end
        end
      end
    end
  end

  ############################################################################

  class TestHashGenericKeyPresenterNoValues < Hoodoo::Presenters::Base
    schema do
      hash :generic do
        keys :length => 6
      end
    end
  end

  ############################################################################

  context 'generic keys no values' do
    context '#validate' do
      it 'should return [] when valid object' do
        data = { 'generic' => { 'one' => 'anything' } }
        expect( TestHashGenericKeyPresenterNoValues.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct errors with invalid keys' do
        data   = { 'generic' => { 'one' => 'anything',
                                  'two' => 'anything',
                                  'toolong' => 'anything',
                                  'evenlonger' => 'anything' } }
        errors = [
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.toolong` is longer than maximum length `6`',
            'reference' => 'generic.toolong'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.evenlonger` is longer than maximum length `6`',
            'reference' => 'generic.evenlonger'
          }
        ]

        expect( TestHashGenericKeyPresenterNoValues.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should render correctly' do

        # Use of "values" is important as it tests for a collision with
        # an internal same-named property. It's an implementation detail
        # which the code should deal with internally correctly, leading
        # to no disernable alteration in expected rendering for callers.

        data   = { 'generic' => { 'one'    => 'anything 1',
                                  'values' => 'should not be overwritten',
                                  'two'    => 'anything 2' } }

        result = TestHashGenericKeyPresenterNoValues.render( data )
        expect( result ).to eq( data )
      end
    end
  end

  ############################################################################

  class TestHashGenericKeyPresenterWithValues < Hoodoo::Presenters::Base
    schema do
      hash :generic do
        keys :length => 4 do
          string :foo, :length => 10
          text :bar
        end
      end
    end
  end

  ############################################################################

  context 'generic keys with values' do
    context '#validate' do
      it 'should return [] when valid object' do
        data = { 'generic' => { 'one' => { 'foo' => 'foov' } } }
        expect( TestHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct errors with invalid keys' do
        data   = { 'generic' => { 'one' => { 'foo' => 'foov' },
                                  'two' => { 'bar' => 'barv' },
                                  'toolong' => { 'foo' => 'foov' },
                                  'evenlonger' => { 'bar' => 'barv' } } }
        errors = [
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.toolong` is longer than maximum length `4`',
            'reference' => 'generic.toolong'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.evenlonger` is longer than maximum length `4`',
            'reference' => 'generic.evenlonger'
          }
        ]

        expect( TestHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct errors with invalid values' do
        data   = { 'generic' => { 'one' => { 'foo' => 'foov' },
                                  'two' => 'not-an-object' } }
        errors = [
          {
            'code'      => 'generic.invalid_object',
            'message'   => 'Field `generic.two` is an invalid object',
            'reference' => 'generic.two'
          }
        ]

        expect( TestHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct errors with invalid keys and values' do
        data   = { 'generic' => { 'one' => 'not-an-object',
                                  'two' => { 'bar' => 'barv' },
                                  'toolong' => 'not-an-object',
                                  'evenlonger' => { 'bar' => 'barv' } } }
        errors = [
          {
            'code'      => 'generic.invalid_object',
            'message'   => 'Field `generic.one` is an invalid object',
            'reference' => 'generic.one'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.toolong` is longer than maximum length `4`',
            'reference' => 'generic.toolong'
          },
          {
            'code'      => 'generic.invalid_object',
            'message'   => 'Field `generic.toolong` is an invalid object',
            'reference' => 'generic.toolong'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.evenlonger` is longer than maximum length `4`',
            'reference' => 'generic.evenlonger'
          }
        ]

        expect( TestHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should only render expected fields' do

        valid  = { 'generic' => { 'one' => {                       'foo' => '<= 10 long' }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv'                     }, 'two' => { 'bar' => 'barv 2' } } }
        data   = { 'generic' => { 'one' => { 'random' => 'ignore', 'foo' => '<= 10 long' }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'hello' => 'there' }, 'two' => { 'bar' => 'barv 2' } } }

        result = TestHashGenericKeyPresenterWithValues.render( data )
        expect( result ).to eq( valid )
      end
    end
  end

  context 'generic keys no values' do
    context '#validate' do
      it 'should return [] when valid object' do
        data = { 'generic' => { 'one' => 'anything' } }
        expect( TestHashGenericKeyPresenterNoValues.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct errors with invalid keys' do
        data   = { 'generic' => { 'one' => 'anything',
                                  'two' => 'anything',
                                  'toolong' => 'anything',
                                  'evenlonger' => 'anything' } }
        errors = [
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.toolong` is longer than maximum length `6`',
            'reference' => 'generic.toolong'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `generic.evenlonger` is longer than maximum length `6`',
            'reference' => 'generic.evenlonger'
          }
        ]

        expect( TestHashGenericKeyPresenterNoValues.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should render correctly' do

        # Use of "values" is important as it tests for a collision with
        # an internal same-named property. It's an implementation detail
        # which the code should deal with internally correctly, leading
        # to no disernable alteration in expected rendering for callers.

        data   = { 'generic' => { 'one'    => 'anything 1',
                                  'values' => 'should not be overwritten',
                                  'two'    => 'anything 2' } }

        result = TestHashGenericKeyPresenterNoValues.render( data )
        expect( result ).to eq( data )
      end
    end
  end

  ############################################################################

  class TestNestedHashGenericKeyPresenterWithValues < Hoodoo::Presenters::Base
    schema do
      object :obj do
        hash :generic do
          keys :length => 4 do
            string :foo, :length => 10
            text :bar
            hash :baz do
              keys do
                string :inner_string, :length => 5
              end
            end
          end
        end
      end
    end
  end

  ############################################################################

  context 'nested generic keys with values' do
    context '#validate' do
      it 'should return [] when valid object' do
        data = { 'obj' => { 'generic' => { 'one' => { 'foo' => 'foov' } } } }
        expect( TestNestedHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( [] )
      end

      it 'should return correct errors with invalid keys' do
        data   = { 'obj' => { 'generic' => { 'one' => { 'foo' => 'foov' },
                                             'two' => { 'bar' => 'barv' },
                                             'toolong' => { 'foo' => 'foov' },
                                             'evenlonger' => { 'bar' => 'barv' },
                                             'ok' => { 'baz' => { 'anything' => { 'inner_string' => 'toolong' } } } } } }
        errors = [
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `obj.generic.toolong` is longer than maximum length `4`',
            'reference' => 'obj.generic.toolong'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `obj.generic.evenlonger` is longer than maximum length `4`',
            'reference' => 'obj.generic.evenlonger'
          },
          {
            'code'      => 'generic.invalid_string',
            'message'   => 'Field `obj.generic.ok.baz.anything.inner_string` is longer than maximum length `5`',
            'reference' => 'obj.generic.ok.baz.anything.inner_string'
          }
        ]

        expect( TestNestedHashGenericKeyPresenterWithValues.validate( data ).errors ).to eq( errors )
      end
    end

    context '#render' do
      it 'should only render expected fields' do

        valid  = {                 'obj' => { 'generic' => { 'one' => {                       'foo' => '<= 10 long' }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'baz' => { 'any' => {                  'inner_string' => 'hi' } }                     }, 'two' => { 'bar' => 'barv 2' } } } }
        data   = { 'number' => 42, 'obj' => { 'generic' => { 'one' => { 'random' => 'ignore', 'foo' => '<= 10 long' }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'baz' => { 'any' => { 'hi' => 'there', 'inner_string' => 'hi' } }, 'hello' => 'there' }, 'two' => { 'bar' => 'barv 2' } } } }

        result = TestNestedHashGenericKeyPresenterWithValues.render( data )
        expect( result ).to eq( valid )
      end
    end
  end

  ############################################################################

  class TestHashGenericKeyPresenterWithRequirements < Hoodoo::Presenters::Base
    schema do
      hash :generic do
        keys :length => 4, :required => true do
          string :foo, :length => 10
          text :bar, :required => true
        end
      end
    end
  end

  ############################################################################

  context 'generic keys with requirements' do
    context '#validate' do
      it 'should return [] when valid object with keys' do
        data = { 'generic' => { 'one' => { 'foo' => 'foov', 'bar' => 'hello' } } }
        expect( TestHashGenericKeyPresenterWithRequirements.validate( data ).errors ).to eq( [] )
      end

      # The Hash itself isn't required; only its keys are, so if 'nil' that
      # should not cause an error.
      #
      it 'should return [] with valid missing hash' do
        data = { 'generic' => nil }
        expect( TestHashGenericKeyPresenterWithRequirements.validate( data ).errors ).to eq( [] )
      end

      # The Hash itself isn't required; only its keys are, so if present but
      # empty (no keys), that should cause an error.
      #
      it 'should return correct errors with missing hash' do
        data   = { 'generic' => {} }
        errors = [
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `generic` is required (Hash, if present, must contain at least one key)',
            'reference' => 'generic'
          }
        ]

        expect( TestHashGenericKeyPresenterWithRequirements.validate( data ).errors ).to eq( errors )
      end

      it 'should return correct errors with missing keys in hash' do
        data   = { 'generic' => { 'one' => { 'foo' => 'foov' } } }
        errors = [
          {
            'code'      => 'generic.required_field_missing',
            'message'   => 'Field `generic.one.bar` is required',
            'reference' => 'generic.one.bar'
          }
        ]

        expect( TestHashGenericKeyPresenterWithRequirements.validate( data ).errors ).to eq( errors )
      end
    end
  end

  ############################################################################

  it 'complains about generic default keys as they are meaningless' do
    expect {
      class TestHashGenericKeyPresenterWithMeaninglessDefaults < Hoodoo::Presenters::Base
        schema do
          hash :generic_defaults do
            keys :length => 4, :default => { 'meaningless' => 'complain' } do
              text :baz
            end
          end
        end
      end
    }.to raise_error(RuntimeError)
  end

  class TestHashGenericKeyPresenterWithDefaults < Hoodoo::Presenters::Base
    schema do
      hash :generic_defaults, :default => { 'a_default_key' => { 'baz' => 'merge' }, 'a_nil_key' => nil } do
        keys :length => 4 do
          string :foo, :length => 10
          text :bar, :default => 'default for text field'
          text :baz
        end
      end
    end
  end

  class TestHashGenericKeyPresenterWithDefaultsExceptHash < Hoodoo::Presenters::Base
    schema do
      hash :generic_defaults do
        keys :length => 4 do
          string :foo, :length => 10
          text :bar, :default => 'default for text field'
          text :baz
        end
      end
    end
  end

  ############################################################################

  context 'generic keys with defaults' do
    context '#render' do

      # The hash itself has a default set, so if the hash key is omitted we
      # expect to get the canned default hash instead. This outer default is
      # rendered, so the key(s) it specifies get individually run through
      # the renderer. If the value is nil, it'll gain the whole-value default.
      # Otherwise, it gains in-block defaults (if any).
      #
      it 'should render with correct default for whole hash (1)' do
        result = TestHashGenericKeyPresenterWithDefaults.render( {} )

        expect( result ).to eq({
          'generic_defaults' => {
            'a_default_key' => { 'bar' => 'default for text field', 'baz' => 'merge' },
            'a_nil_key'     => nil
          }
        })
      end

      # Explicit nil means nil, but at the top level we have to treat it as an
      # empty hash so it'll give the same result.
      #
      it 'should render with correct default for whole hash (2)' do
        result = TestHashGenericKeyPresenterWithDefaults.render( nil )

        expect( result ).to eq({
          'generic_defaults' => {
            'a_default_key' => { 'bar' => 'default for text field', 'baz' => 'merge' },
            'a_nil_key'     => nil
          }
        })
      end

      # If we explicitly give a value for the hash, then that should override
      # the hash-wide default, even if empty...
      #
      it 'should render with correct defaults for hash keys (1)' do
        data   = { 'generic_defaults' => {} }
        result = TestHashGenericKeyPresenterWithDefaults.render( data )

        expect( result ).to eq({
          'generic_defaults' => {}
        })
      end

      # ...However explicit nil means nil...
      #
      it 'should render with correct defaults for hash keys (2)' do
        data   = { 'generic_defaults' => nil }
        result = TestHashGenericKeyPresenterWithDefaults.render( data )
        expect( result ).to eq(data)
      end

      # ...and explicitly defined keys with nil values should be nil too.
      #
      it 'should render with correct defaults for hash keys (3)' do
        data   = { 'generic_defaults' => { 'hello' => nil, 'goodbye' => {}, 'another' => { 'foo' => 'present', 'bar' => 'also present' } } }
        result = TestHashGenericKeyPresenterWithDefaults.render( data )

        expect( result ).to eq({
          'generic_defaults' => {
            'hello'   => nil,
            'goodbye' => {                     'bar' => 'default for text field' },
            'another' => { 'foo' => 'present', 'bar' => 'also present'           }
          }
        })
      end

      # No hash default now. An empty hash can only be rendered as an empty
      # hash, because we don't have any default key names or hash-wide default
      # to use as a template.
      #
      it 'should render with correct default for whole hash (1)' do
        result = TestHashGenericKeyPresenterWithDefaultsExceptHash.render( {} )
        expect( result ).to eq({})
      end

      # Should behave the same with 'nil'.
      #
      it 'should render with correct default for whole hash (2)' do
        result = TestHashGenericKeyPresenterWithDefaultsExceptHash.render( nil )
        expect( result ).to eq({})
      end

      # If we explicitly give a value for the hash, should get the empty hash
      # recorded...
      #
      it 'should render with correct defaults for hash keys (1)' do
        data   = { 'generic_defaults' => {} }
        result = TestHashGenericKeyPresenterWithDefaultsExceptHash.render( data )
        expect( result ).to eq({ 'generic_defaults' => {} })
      end

      # ...explicit nil means nil...
      #
      it 'should render with correct defaults for hash keys (2)' do
        data   = { 'generic_defaults' => nil }
        result = TestHashGenericKeyPresenterWithDefaultsExceptHash.render( data )
        expect( result ).to eq({ 'generic_defaults' => nil })
      end

      # ...and when we have keys supplied, the usual default rules should apply.
      #
      it 'should render with correct defaults for hash keys (3)' do
        data   = { 'generic_defaults' => { 'hello' => nil, 'goodbye' => {}, 'another' => { 'foo' => 'present', 'bar' => 'also present' } } }
        result = TestHashGenericKeyPresenterWithDefaultsExceptHash.render( data )

        expect( result ).to eq({
          'generic_defaults' => {
            'hello'   => nil,
            'goodbye' => {                     'bar' => 'default for text field' },
            'another' => { 'foo' => 'present', 'bar' => 'also present'           }
          }
        })
      end
    end
  end

  ############################################################################

  KEYS_DATA = {
    'array'      => { :definition => { :length => 9, :type => :array                                                 }, :valid => [ [ 2, 3, 4 ]             ], :invalid => [ 4, { :one => 1 }                 ] },
    'boolean'    => { :definition => { :length => 9, :type => :boolean                                               }, :valid => [ true                    ], :invalid => [ 4.51, 'false'                    ] },
    'date'       => { :definition => { :length => 9, :type => :date                                                  }, :valid => [ Date.today.iso8601      ], :invalid => [ Date.today, '23rd January 2041'  ] },
    'date_time'  => { :definition => { :length => 9, :type => :date_time                                             }, :valid => [ DateTime.now.iso8601    ], :invalid => [ DateTime.now, '2017-01-27 12:00' ] },
    'decimal'    => { :definition => { :length => 9, :type => :decimal,   :field_precision => 2                      }, :valid => [ '4.51'                  ], :invalid => [ 4.51, BigDecimal.new( '4.51' )   ] },
    'enum'       => { :definition => { :length => 9, :type => :enum,      :field_from      => [ :one, :two, :three ] }, :valid => [ 'one'                   ], :invalid => [ 'One', 1                         ] },
    'float'      => { :definition => { :length => 9, :type => :float                                                 }, :valid => [ 4.51                    ], :invalid => [ BigDecimal.new(4.51, 2), '4.51'  ] },
    'integer'    => { :definition => { :length => 9, :type => :integer                                               }, :valid => [ 4                       ], :invalid => [ '4'                              ] },
    'string'     => { :definition => { :length => 9, :type => :string,    :field_length    => 4                      }, :valid => [ 'four'                  ], :invalid => [ 'toolong', 4, true               ] },
    'tags'       => { :definition => { :length => 9, :type => :tags                                                  }, :valid => [ 'tag_a,tag_b,tag_c'     ], :invalid => [ 4, true                          ] },
    'text'       => { :definition => { :length => 9, :type => :text                                                  }, :valid => [ 'hello world'           ], :invalid => [ 4, true                          ] },
    'uuid'       => { :definition => { :length => 9, :type => :uuid                                                  }, :valid => [ Hoodoo::UUID.generate() ], :invalid => [ '123456', 4, true                ] },
    'field'      => { :definition => { :length => 9                                                                  }, :valid => [ 4, '4', { :one => 1 }   ], :invalid => [                                  ] },
    '1234567890' => { :definition => { :length => 9                                                                  }, :valid => [                         ], :invalid => [ 'Any value; key is too long'     ] },
 }

  KEYS_DATA.each do | field, values |
    context "keys with elementary type '#{ values[ :definition ][ :type ] || 'field' }'" do
      before :all do

        # Flatten local scope to access 'values' inside the class definition;
        # see e.g.:
        #
        #   https://gist.github.com/Integralist/a29212a8eb10bc8154b7#file-07-flattening-the-scope-aka-nested-lexical-scopes-rb
        #
        # Per-key defaults don't apply to generic Hashes because a key is
        # either given to validate or render with in the caller-provided
        # input parameters, in which case it already must have a value -
        # even if explicitly "nil" - or the key is absent, in which case
        # we have nothing to associate a daefault value with.
        #
        # Per-hash full defaults are supported but we can't really do those
        # here as valid defaults will change for every line in KEYS_DATA
        # with the changing types required by the keys.
        #
        @test_class = Class.new( Hoodoo::Presenters::Base ) do
          schema do
            hash :keys_types do
              keys( values[ :definition ] )
            end
          end
        end
      end

      context '#render' do
        values[ :valid ].each_with_index do | value, index |
          it "renders correctly for '#{ field }' (#{ index + 1 })" do
            data = { 'keys_types' => { field => value } }
            expect( @test_class.render( data ) ).to eq( data )
          end
        end
      end

      context '#validate' do
        values[ :valid ].each_with_index do | value, index |
          it "accepts a valid value for '#{ field }' (#{ index + 1 })" do
            data = { 'keys_types' => { field => value } }
            expect( @test_class.validate( data ).errors.size ).to( eql( 0 ) )
          end
        end

        values[ :invalid ].each_with_index do | value, index |
          it "rejects an invalid value for '#{ field }' (#{ index + 1 })" do
            data = { 'keys_types' => { field => value } }
            expect( @test_class.validate( data ).errors.size ).to( eql( 1 ) )
          end
        end
      end
    end
  end

  ############################################################################

  class TestHashKeyDefaultAggregation < Hoodoo::Presenters::Base
    schema do
      hash :test, :default => { :three => 3 } do

        key :one,   :default => { :foo => 'bar' }
        key :two,   :default => { 'bar' => :baz }
        key :three, :type    => :integer

      end
    end
  end

  it 'aggregates default shallow Hash and key values' do
    expected = {
      'test' => {
        'one'   => { 'foo' => 'bar' },
        'two'   => { 'bar' => :baz  },
        'three' => 3
      }
    }

    expect( TestHashKeyDefaultAggregation.render( {} ) ).to eql( expected )
  end

  it 'overrides default shallow Hash values' do
    data = {
      'test' => {}
    }

    expected =  {
      'test' => {
        'one'   => { 'foo' => 'bar' }, # From the key default
        'two'   => { 'bar' => :baz  }  # From the key default
        # No 'three'; we fully overrode the top-level Hash default in 'data'
      }
    }

    expect( TestHashKeyDefaultAggregation.render( data ) ).to eql( expected )
  end

  it 'overrides shallow default key values' do
    data = {
      'test' => {
        'two' => { 'foo' => 'baz' }
      }
    }

    expected =  {
      'test' => {
        'one'   => { 'foo' => 'bar' }, # From the key default
        'two'   => { 'foo' => 'baz' }  # From 'data' above
        # No 'three'; we fully overrode the top-level Hash default in 'data'
      }
    }

    expect( TestHashKeyDefaultAggregation.render( data ) ).to eql( expected )
  end

  # TODO: This class does not work as originally hoped.
  # TODO: Illustrates workaround in https://github.com/LoyaltyNZ/hoodoo/issues/194
  # TODO: Move default off ":two" and into ":inner_two" if above is addressed.
  #
  class TestHashKeyDeepDefaultAggregation < Hoodoo::Presenters::Base
    schema do
      hash :test do # A default here would implicitly override anything on :two below

        key :one,   :default => { :foo => 'bar' }
        key :three, :type    => :integer

        key :two, :default => { 'inner_two' => { 'inner_three' => 'three' } } do
          hash :inner_two do
            key :inner_one,   :default => { :bar => 'baz' }
            key :inner_three, :type    => :text
          end
        end
      end
    end
  end

  it 'aggregates default deep Hash and key values' do
    expected = {
      'test' => {
        'one'   => { 'foo' => 'bar' },
        'two'   => {
          'inner_two' => {
            'inner_one'   => { 'bar' => 'baz' },
            'inner_three' => 'three'
          }
        }
      }
    }

    expect( TestHashKeyDeepDefaultAggregation.render( {} ) ).to eql( expected )
  end

  it 'overrides shallow deep Hash values, preserving deep values' do
    data = {
      'test' => {}
    }

    expected =  {
      'test' => {
        'one' => { 'foo' => 'bar' }, # From the key default
        # No 'three'; we fully overrode the top-level Hash default in 'data'
        'two' => {
          'inner_two' => {
            'inner_one' => { 'bar' => 'baz' },  # From the key default
            'inner_three' => 'three' # From the deep Hash default
          }
        }
      }
    }

    expect( TestHashKeyDeepDefaultAggregation.render( data ) ).to eql( expected )
  end

  it 'overrides default deep Hash values' do
    data = {
      'test' => {
        'two' => {
        }
      }
    }

    expected =  {
      'test' => {
        'one' => { 'foo' => 'bar' }, # From the key default
        # No 'three'; we fully overrode the top-level Hash default in 'data'
        'two' => {
          'inner_two' => {
            'inner_one' => { 'bar' => 'baz' } # From the key default
            # No 'inner_three'; we overrode the deep Hash default in 'data'
          }
        }
      }
    }

    expect( TestHashKeyDeepDefaultAggregation.render( data ) ).to eql( expected )
  end

  it 'overrides deep deep key values' do
    data = {
      'test' => {
        'two' => {
          'inner_two' => {
            'inner_one' => { 'bar' => 'hello' }
          }
        }
      }
    }

    expected =  {
      'test' => {
        'one' => { 'foo' => 'bar' }, # From the key default
        # No 'three'; we fully overrode the top-level Hash default in 'data'
        'two' => {
          'inner_two' => {
            'inner_one' => { 'bar' => 'hello' } # From 'data' above
            # No 'inner_three'; we overrode the deep Hash default in 'data'
          }
        }
      }
    }

    expect( TestHashKeyDeepDefaultAggregation.render( data ) ).to eql( expected )
  end

  ############################################################################

  context 'RDoc examples' do
    class TestHypotheticaHashCurrency < Hoodoo::Presenters::Base
      schema do
        string :currency_code, :length => 16
        integer :precision
      end
    end

    context 'CurrencyHash' do
      class TestCurrencyHash < Hoodoo::Presenters::Base
        schema do
          hash :currencies do
            keys :length => 16 do
              type TestHypotheticaHashCurrency
            end
          end
        end
      end

      let( :valid_data ) do
        {
          'currencies' => {
            'one' => {
              'currency_code' => 'X_HOODOO_LO',
              'precision' => 1
            },
            '0123456789ABCDEF' => {
              'currency_code' => 'X_HOODOO_HI',
              'precision' => 4
            }
          }
        }
      end

      context '#validate' do
        it 'enforces field and key restrictions' do
          data = {
            'currencies' => {
              'one' => {
                'currency_code' => 'too long a currency code',
                'precision' => 1
              },
              '0123456789ABCDEF' => {
                'currency_code' => 'X_HOODOO_HI',
                'precision' => 'not an integer'
              },
              'too long a key name overall' => {
                'currency_code' => 'X_HOODOO_LO',
                'precision' => 1
              }
            }
          }

          errors = TestCurrencyHash.validate( data ).errors

          expect( errors.size ).to( eql( 3 ) )

          expect( errors[ 0 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 0 ][ 'reference' ] ).to( eql( 'currencies.one.currency_code' ) )

          expect( errors[ 1 ][ 'code'      ] ).to( eql( 'generic.invalid_integer' ) )
          expect( errors[ 1 ][ 'reference' ] ).to( eql( 'currencies.0123456789ABCDEF.precision' ) )

          expect( errors[ 2 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 2 ][ 'reference' ] ).to( eql( 'currencies.too long a key name overall' ) )
        end

        it 'is happy with valid data' do
          expect( TestCurrencyHash.validate( valid_data() ).errors.size ).to( eql( 0 ) )
        end
      end

      context '#render' do
        it 'renders valid data' do
          expect( TestCurrencyHash.render( valid_data() ) ).to( eql( valid_data() ) )
        end
      end
    end

    context 'AltCurrencyHash' do
      class TestAltCurrencyHash < Hoodoo::Presenters::Base
        schema do
          hash :currencies do
            key :one do
              type TestHypotheticaHashCurrency
            end

            key :two do
              text :title
              text :description
            end
          end
        end
      end

      let( :valid_data ) do
        {
          'currencies' => {
            'one' => {
              'currency_code' => 'X_HOODOO_LO',
              'precision' => 1
            },
            'two' => {
              'title' => 'Optional title text',
              'description' => 'Optional description text'
            }
          }
        }
      end

      context '#validate' do
        it 'enforces field restrictions' do
          data = {
            'currencies' => {
              'one' => {
                'currency_code' => 'too long a currency code',
                'precision' => 1
              }
            }
          }

          errors = TestAltCurrencyHash.validate( data ).errors

          expect( errors.size ).to( eql( 1 ) )
          expect( errors[ 0 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 0 ][ 'reference' ] ).to( eql( 'currencies.one.currency_code' ) )
        end

        it 'enforces key name restrictions' do
          data = {
            'currencies' => {
              'unrecognised' => {
                'currency_code' => 'X_HOODOO_LO',
                'precision' => 1
              }
            }
          }

          errors = TestAltCurrencyHash.validate( data ).errors

          expect( errors.size ).to( eql( 1 ) )
          expect( errors[ 0 ][ 'code'      ] ).to( eql( 'generic.invalid_hash' ) )
          expect( errors[ 0 ][ 'reference' ] ).to( eql( 'currencies' ) )
        end

        it 'is happy with valid data' do
          expect( TestAltCurrencyHash.validate( valid_data() ).errors.size ).to( eql( 0 ) )
        end
      end

      context '#render' do
        it 'renders valid data' do
          expect( TestAltCurrencyHash.render( valid_data() ) ).to( eql( valid_data() ) )
        end
      end
    end

    context 'Person' do
      class TestPerson < Hoodoo::Presenters::Base
        schema do
          hash :name do
            key :first, :type => :text
            key :last,  :type => :text
          end

          hash :address do
            keys :type => :text
          end

          hash :identifiers, :required => true do
            keys :length => 8, :type => :string, :field_length => 32
          end
        end
      end

      let( :valid_data ) do
        {
          'name' => {
            'first' => 'Test',
            'last' => 'Testy'
          },
          'address' => {
            'road' => '1 Test Street',
            'city' => 'Testville',
            'post_code' => 'T01 C41'
          },
          'identifiers' => {
            'primary' => '9759c77d188f4bfe85959738dc6f8505',
            'postgres' => '1442'
          }
        }
      end

      context '#validate' do
        it 'enforces a required hash' do
          data = Hoodoo::Utilities.deep_dup( valid_data() )
          data.delete( 'identifiers' )

          errors = TestPerson.validate( data ).errors

          expect( errors.size ).to( eql( 1 ) )
          expect( errors[ 0 ][ 'code'      ] ).to( eql( 'generic.required_field_missing' ) )
          expect( errors[ 0 ][ 'reference' ] ).to( eql( 'identifiers' ) )
        end

        it 'enforces field and key restrictions' do
          data = {
            'name' => {
              'first' => 'Test',
              'surname' => 'Testy' # Invalid key name
            },
            'address' => {
              'road' => '1 Test Street',
              'city' => 'Testville',
              'zip' => 90421 # Integer, not Text
            },
            'identifiers' => {
              'primary' => '9759c77d188f4bfe85959738dc6f8505_441', # Value too long
              'postgresql' => '1442' # Key name too long
            }
          }

          errors = TestPerson.validate( data ).errors

          expect( errors.size ).to( eql( 4 ) )

          expect( errors[ 0 ][ 'code'      ] ).to( eql( 'generic.invalid_hash' ) )
          expect( errors[ 0 ][ 'reference' ] ).to( eql( 'name' ) )

          expect( errors[ 1 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 1 ][ 'reference' ] ).to( eql( 'address.zip' ) )

          expect( errors[ 2 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 2 ][ 'reference' ] ).to( eql( 'identifiers.primary' ) )

          expect( errors[ 3 ][ 'code'      ] ).to( eql( 'generic.invalid_string' ) )
          expect( errors[ 3 ][ 'reference' ] ).to( eql( 'identifiers.postgresql' ) )
        end

        it 'is happy with valid data' do
          expect( TestPerson.validate( valid_data() ).errors.size ).to( eql( 0 ) )
        end
      end

      context '#render' do
        it 'renders valid data' do
          expect( TestPerson.render( valid_data() ) ).to( eql( valid_data() ) )
        end
      end
    end
  end

end
