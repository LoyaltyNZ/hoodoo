require 'spec_helper'

class TestHashNoKeysPresenter < ApiTools::Presenters::BasePresenter
  schema do
    hash :specific
  end
end

class TestHashNoKeysPresenterRequired < ApiTools::Presenters::BasePresenter
  schema do
    hash :specific_required, :required => true
  end
end

class TestHashSpecificKeyPresenter < ApiTools::Presenters::BasePresenter
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

class TestNestedHashSpecificKeyPresenter < ApiTools::Presenters::BasePresenter
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

class TestHashSpecificKeyPresenterWithRequirements < ApiTools::Presenters::BasePresenter
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

class TestHashGenericKeyPresenterNoValues < ApiTools::Presenters::BasePresenter
  schema do
    hash :generic do
      keys :length => 6
    end
  end
end

class TestHashGenericKeyPresenterWithValues < ApiTools::Presenters::BasePresenter
  schema do
    hash :generic do
      keys :length => 4 do
        string :foo, :length => 10
        text :bar
      end
    end
  end
end

class TestNestedHashGenericKeyPresenterWithValues < ApiTools::Presenters::BasePresenter
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









puts "*"*80
puts "Still to test - nesting; default; requirements for the generic key stuff; parse (also for array/object)"
puts "*"*80










describe ApiTools::Presenters::Hash do

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

        expect( result ).to eq( 'specific' => {} )
      end
    end
  end

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
        data = { 'specific' => { 'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } } }
        expect( TestHashSpecificKeyPresenter.validate( data ).errors ).to eq( [] )
      end

      it 'should return [] when valid object (4)' do
        data = { 'specific' => { 'one' => 'anything',
                                 'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                                 'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } } }

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
                                 'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } } }
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
            'message'   => 'Field `specific.three.id` has incorrect length 9 for a UUID (should be 32)',
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
        data   = { 'specific' => { 'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should render correctly (4)' do
        data   = { 'specific' => { 'one' => 'anything',
                                   'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                                   'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } } }
        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( data )
      end

      it 'should ignore unspecified entries' do
        inner = { 'one' => 'anything',
                  'two' => { 'foo' => 'foov', 'bar' => 'barv' },
                  'three' => { 'int' => 23, 'id' => ApiTools::UUID.generate() } }

        valid = { 'specific' => inner.dup }
        data  = { 'specific' => inner.dup }

        data[ 'generic' ] = 'hello'
        data[ 'specific' ][ 'random' ] = 23

        result = TestHashSpecificKeyPresenter.render( data )

        expect( result ).to eq( valid )
      end
    end
  end

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
        valid  = { 'obj' => { 'obj_text' => 'hello',                   'specific' => { 'two' => { 'two_key_string' => nil, 'two_key_hash' => { 'inner' => 42, 'inner_2' => { 'inner_2_string' => 'ok' } } } } } }
        data   = { 'obj' => { 'obj_text' => 'hello', 'random' => true, 'specific' => { 'two' => {                          'two_key_hash' => { 'inner' => 42, 'inner_2' => { 'inner_2_string' => 'ok' } } } } } }

        result = TestNestedHashSpecificKeyPresenter.render( data )
        expect( result ).to eq( valid )
      end
    end
  end

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

        valid  = { 'generic' => { 'one' => {                       'foo' => '<= 10 long', 'bar' => nil }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv'                     }, 'two' => { 'foo' => nil, 'bar' => 'barv 2' } } }
        data   = { 'generic' => { 'one' => { 'random' => 'ignore', 'foo' => '<= 10 long'               }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'hello' => 'there' }, 'two' => {               'bar' => 'barv 2' } } }

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

        valid  = {                 'obj' => { 'generic' => { 'one' => {                       'foo' => '<= 10 long', 'bar' => nil, 'baz' => {} }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'baz' => { 'any' => {                  'inner_string' => 'hi' } }                     }, 'two' => { 'foo' => nil, 'bar' => 'barv 2', 'baz' => {} } } } }
        data   = { 'number' => 42, 'obj' => { 'generic' => { 'one' => { 'random' => 'ignore', 'foo' => '<= 10 long'                            }, 'values' => { 'foo' => '<= 10 2', 'bar' => 'barv', 'baz' => { 'any' => { 'hi' => 'there', 'inner_string' => 'hi' } }, 'hello' => 'there' }, 'two' => {               'bar' => 'barv 2'              } } } }

        result = TestNestedHashGenericKeyPresenterWithValues.render( data )
        expect( result ).to eq( valid )
      end
    end
  end
end