require "spec_helper"


# This specific file just tests the presenter layer "#walk" method. It
# uses (at the time of writing) every single kind of schema field to
# varying degrees (where possible, e.g. "object") of complexity and
# then runs one "walk" call over the whole thing to verify that it does
# get called on every node.

describe Hoodoo::Presenters::Base do
  before do
    class TestWalkPresenterA < Hoodoo::Presenters::Base
      schema do

        # Simple fields

        boolean  :test_boolean
        datetime :test_datetime
        date     :test_date
        decimal  :test_decimal, :precision => 2
        enum     :test_enum, :from => [ :one, :two ]
        float    :test_float
        integer  :test_integer
        string   :test_string, :length => 8
        tags     :test_tags
        text     :test_text
        uuid     :test_uuid

        # Objects, in their various permitted forms

        object :test_object_2 do
          text :test_object_2_text_1
          text :test_object_2_text_2
        end

        object :test_object_3 do
          text :test_object_3_text_1
          object :test_object_3_object_1 do
            text :test_object_3_object_1_text_1
          end
          array :test_object_3_array_1 do
            text :test_object_3_array_1_text_1
            text :test_object_3_array_1_text_2
          end
          text :test_object_3_text_2
        end

        # Arrays, in their various permitted forms

        array :text_array_1

        array :test_array_2 do
          text :test_array_2_text_1
          text :test_array_2_text_2
        end

        array :test_array_3 do
          text :test_array_3_text_1
          object :test_array_3_object_1 do
            text :test_array_3_object_1_text_1
            text :test_array_3_object_1_text_2
          end
          text :test_array_3_text_2
        end

        # Hashes, in their various complex permitted forms

        hash :test_hash_1

        hash :test_hash_2 do
          key :test_hash_2_key_1 do
            text :test_hash_2_key_1_text_1
            object :test_hash_2_key_1_object_1 do
              text :test_hash_2_key_1_object_1_text_1
            end
          end
          key :test_hash_2_key_2 do
            array :test_hash_2_key_2_array_1 do
              text :test_hash_2_key_2_array_1_text_1
            end
          end
        end

        hash :test_hash_3 do
          keys do
            text :test_hash_3_keys_text_1
            object :test_hash_3_keys_object_1 do
              text :test_hash_3_keys_object_1_text_1
            end
            array :test_hash_3_keys_array_1 do
              text :test_hash_3_keys_array_1_text_1
            end
          end
        end

        hash :test_hash_4 do
          keys :length => 4
        end

      end # 'schema do'
    end   # 'class TestWalkPresenter < Hoodoo::Presenters::Base'

    class TestWalkPresenterB < Hoodoo::Presenters::Base
      schema do
        text :simple_text
      end
    end

    class TestWalkPresenterC < Hoodoo::Presenters::Base
      schema do
      end
    end

  end # 'before do'

  context '#walk' do
    it 'handles complex tree' do
      names = []

      TestWalkPresenterA.walk do | property |
        names << property.name
      end

      expected_names = [ '' ] + %w{
        test_boolean
        test_datetime
        test_date
        test_decimal
        test_enum
        test_float
        test_integer
        test_string
        test_tags
        test_text
        test_uuid
        test_object_2
        test_object_2_text_1
        test_object_2_text_2
        test_object_3
        test_object_3_text_1
        test_object_3_object_1
        test_object_3_object_1_text_1
        test_object_3_array_1
        test_object_3_array_1_text_1
        test_object_3_array_1_text_2
        test_object_3_text_2
        text_array_1
        test_array_2
        test_array_2_text_1
        test_array_2_text_2
        test_array_3
        test_array_3_text_1
        test_array_3_object_1
        test_array_3_object_1_text_1
        test_array_3_object_1_text_2
        test_array_3_text_2
        test_hash_1
        test_hash_2
        test_hash_2_key_1
        test_hash_2_key_1_text_1
        test_hash_2_key_1_object_1
        test_hash_2_key_1_object_1_text_1
        test_hash_2_key_2
        test_hash_2_key_2_array_1
        test_hash_2_key_2_array_1_text_1
        test_hash_3
        test_hash_3_keys_text_1
        test_hash_3_keys_object_1
        test_hash_3_keys_object_1_text_1
        test_hash_3_keys_array_1
        test_hash_3_keys_array_1_text_1
        test_hash_4
      }

      expect( names ).to eq( expected_names )
    end

    it 'handles simple tree' do
      names = []

      TestWalkPresenterB.walk do | property |
        names << property.name
      end

      expect( names ).to eq( [ '', 'simple_text' ] )
    end

    it 'handles empty tree' do
      names = []

      TestWalkPresenterC.walk do | property |
        names << property.name
      end

      expect( names ).to eq( [ '' ] )
    end
  end
end
