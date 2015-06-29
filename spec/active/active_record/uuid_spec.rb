require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::UUID do
  before :all do
    spec_helper_silence_stdout() do

      # Table with default uuid column (id)
      tblname = :r_spec_model_uuid_tests

      ActiveRecord::Migration.create_table( tblname, :id => false ) do | t |
        t.string( :id, :limit => 32, :null => false )
      end

      ActiveRecord::Migration.add_index( tblname, :id, :unique => true )

      # Table with non-default uuid column (uuid)
      second_tblname = :r_spec_model_uuid_test_custom_uuids

      ActiveRecord::Migration.create_table( second_tblname, :id => false ) do | t |
        t.string( :uuid, :limit => 32, :null => false )
      end

      ActiveRecord::Migration.add_index( second_tblname, :uuid, :unique => true )

      # Hoodoo::ActiveRecord::Base adds a filter to assign a uuid before
      # validation as well as validations to ensure UUID is present and is
      # a valid UUID.
      #
      class RSpecModelUUIDTest < Hoodoo::ActiveRecord::Base
      end

      # As above without the requirement for a unique uuid.
      #
      class RSpecModelUUIDTestCustomUUID < Hoodoo::ActiveRecord::Base
        self.uuid_column = :uuid
      end

    end
  end

  shared_examples "model with uuid" do
    it 'should gain a UUID' do
      m = model_class.new
      m.save

      expect( m.send(uuid_column) ).to_not be_nil
      expect( Hoodoo::UUID.valid?( m.send(uuid_column) ) ).to eq( true )
    end

    it 'should complain about a bad UUID' do
      m = model_class.new
      m.send("#{uuid_column}=", "hello")

      expect( m.save ).to eq( false )
      expect( Hoodoo::UUID.valid?( m.send(uuid_column) ) ).to eq( false )
      expect( m.errors ).to_not be_empty
      expect( m.errors.messages ).to eq( { uuid_column => [ 'is invalid' ] } )
    end

    it 'should not overwrite a good UUID' do
      m = model_class.new
      uuid = Hoodoo::UUID.generate()
      m.send("#{uuid_column}=", uuid)
      m.save

      expect( m.send(uuid_column) ).to eq( uuid )
      expect( Hoodoo::UUID.valid?( m.send(uuid_column) ) ).to eq( true )
    end
  end

  shared_examples "model with unique uuid" do

    it 'should prevent duplicate uuid' do
      uuid = Hoodoo::UUID.generate()

      m = model_class.new
      m.send("#{uuid_column}=", uuid)
      m.save

      duplicate = model_class.new
      duplicate.send("#{uuid_column}=", uuid)
      duplicate.save

      expect( duplicate.errors[uuid_column] ).to eq( [ 'has already been taken' ] )
    end

  end

  shared_examples "model with non-unique uuid" do

    it 'should allow a duplicate uuid if the config option is set' do
      uuid = Hoodoo::UUID.generate()

      m = model_class.new
      m.send("#{uuid_column}=", uuid)
      m.save

      duplicate = model_class.new
      duplicate.send("#{uuid_column}=", uuid)
      duplicate.save

      expect( duplicate.errors[uuid_column] ).to eq( [ 'has already been taken' ] )
    end

  end

  context "default uuid model" do
    let(:model_class){ RSpecModelUUIDTest }
    let(:uuid_column){ :id }

    it_behaves_like "model with uuid"
    it_behaves_like "model with unique uuid"

    context "with unique uuid disabled" do
      let(:model_class) do
        klass = RSpecModelUUIDTest
        klass.validate_uuid_uniqueness = false
        klass
      end

      it_behaves_like "model with non-unique uuid"
    end

  end

  context "uuid model with custom uuid column" do
    let(:model_class){ RSpecModelUUIDTestCustomUUID }
    let(:uuid_column){ :uuid }

    it_behaves_like "model with uuid"
    it_behaves_like "model with unique uuid"

    context "with unique uuid disabled" do
      let(:model_class) do
        klass = RSpecModelUUIDTestCustomUUID
        klass.validate_uuid_uniqueness = false
        klass
      end

      it_behaves_like "model with non-unique uuid"
    end

  end

end
