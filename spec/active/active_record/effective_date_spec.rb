require 'byebug'
require 'spec_helper'
require 'active_record'
require 'timecop'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests ) do | t |
        t.text     :uuid,            :null => false
        t.text     :data
        t.datetime :effective_start, :null => false
        t.datetime :effective_end
        t.timestamps
      end

      class RSpecModelEffectiveDateTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
        self.uuid_column = :uuid
      end

      class RSpecModelEffectiveDateTestHoodoo < Hoodoo::ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
        self.table_name = 'r_spec_model_effective_date_tests'
        self.uuid_column = :uuid
        self.validate_uuid_uniqueness = false
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_field_override_tests, :id => false ) do | t |
        t.text     :unique_id,  :null => false
        t.text     :data
        t.datetime :valid_from, :null => false
        t.datetime :valid_until
        t.timestamps
      end
      class RSpecModelEffectiveDateFieldOverrideTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate

        self.uuid_column                = :unique_id
        self.effective_date_start_field = :valid_from
        self.effective_date_end_field   = :valid_until
      end
    end
  end

  before :each do
    @a = RSpecModelEffectiveDateTest.new
    @b = RSpecModelEffectiveDateTest.new

    @data       = 'some data'
    @other_data = 'some other data'
    @now        = Time.now
  end

  context 'persisting an ActiveRecord model' do

    it 'loads back values set by the database' do

      expect(@a.id).to be_nil
      @a.effective_start = @now
      @a.uuid = Hoodoo::UUID.generate
      @a.save!
      expect(@a.id).to_not be_nil

    end

    it 'creates a new record when updating' do

      @a.data = 'original data'
      @a.uuid = Hoodoo::UUID.generate
      @a.effective_start = @now
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(1)

      @a.data = 'modified data'
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(2)

      @a.data = 'more modified data'
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(3)

      # Check all the data is there
      expect(RSpecModelEffectiveDateTest.pluck(:id, :data)).
        to match_array([
          [1, 'original data'],
          [2, 'modified data'],
          [3, 'more modified data']
      ])
    end
  end

  context 'persisting a Hoodoo::ActiveRecord model' do

    it 'loads back values set by the database' do

      hoodoo_model = RSpecModelEffectiveDateTestHoodoo.new
      hoodoo_model.effective_start = @now

      expect(hoodoo_model.id).to be_nil
      expect(hoodoo_model.uuid).to be_nil

      hoodoo_model.save!

      expect(hoodoo_model.id).to eq(1)
      expect(Hoodoo::UUID.valid?(hoodoo_model.uuid)).to be_truthy

    end

    it 'creates a new record when updating' do

      hoodoo_model = RSpecModelEffectiveDateTestHoodoo.new
      hoodoo_model.data = 'original data'
      hoodoo_model.effective_start = @now
      hoodoo_model.save!
      expect(RSpecModelEffectiveDateTestHoodoo.count).to eq(1)

      hoodoo_uuid = hoodoo_model.uuid

      hoodoo_model.data = 'modified data'
      hoodoo_model.save!
      expect(RSpecModelEffectiveDateTestHoodoo.count).to eq(2)

      hoodoo_model.data = 'more modified data'
      hoodoo_model.save!
      expect(RSpecModelEffectiveDateTestHoodoo.count).to eq(3)

      # Check all the data is there
      expect(RSpecModelEffectiveDateTestHoodoo.pluck(:id, :uuid, :data)).
        to match_array([
          [1, hoodoo_uuid, 'original data'],
          [2, hoodoo_uuid, 'modified data'],
          [3, hoodoo_uuid, 'more modified data']
      ])
    end
  end

  context 'find_at' do
    it 'finds a default record' do
      @a.data = @data
      @a.effective_start = @now
      @a.uuid = '1234'
      @a.save!

      found = RSpecModelEffectiveDateTest.find_at('1234')
      expect(found.data).to eq @data
    end

    it 'finds an end dated record' do
      @a.data = @data
      @a.effective_start = @now
      @a.uuid = '1234'
      @a.effective_end = Time.now + 3.days
      @a.save

      found = RSpecModelEffectiveDateTest.find_at('1234')
      expect(found.data).to eq @data
    end

    context "with many existing records" do
      before do
        @a.data = @data
        @a.uuid = '1234'
        @a.effective_start = @now - 3.days
        @a.effective_end = @now
        @a.save!

        @b.data = @other_data
        @b.effective_start = @now
        @b.uuid = '1234'
        @b.save!
      end

      it 'finds the default' do
        found = RSpecModelEffectiveDateTest.find_at('1234')
        expect(found.data).to eq @other_data
      end
      it 'finds the end dated one by the date' do
        found = RSpecModelEffectiveDateTest.find_at('1234', @now-2.days)
        expect(found.data).to eq @data
      end
      it 'finds the end dated one using its start date' do
        found = RSpecModelEffectiveDateTest.find_at('1234', @now-3.days)
        expect(found.data).to eq @data
      end
      it 'finds the default using its start date' do
        found = RSpecModelEffectiveDateTest.find_at('1234', @now)
        expect(found.data).to eq @other_data
      end
    end

    context "when setting the field names" do
      before do
        @d = RSpecModelEffectiveDateFieldOverrideTest.new
        @e = RSpecModelEffectiveDateFieldOverrideTest.new
      end

      it 'finds a default record' do
        @d.data = @data
        @d.valid_from = @now
        @d.unique_id = '1234'
        @d.save!

        found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234')
        expect(found.data).to eq @data
      end

      it 'finds an end dated record' do
        @d.data = @data
        @d.valid_from = @now
        @d.unique_id = '1234'
        @d.valid_until = Time.now + 3.days
        @d.save!

        found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234')
        expect(found.data).to eq @data
      end

      context "with many existing records" do
        before do
          @d.data = @data
          @d.unique_id = '1234'
          @d.valid_from = @now - 3.days
          @d.valid_until = @now
          @d.save!

          @e.data = @other_data
          @e.valid_from = @now
          @e.unique_id = '1234'
          @e.save!
        end

        it 'finds the default' do
          found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234')
          expect(found.data).to eq @other_data
        end
        it 'finds the end dated one by the date' do
          found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234', @now-2.days)
          expect(found.data).to eq @data
        end
        it 'finds the end dated one using its start date' do
          found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234', @now-3.days)
          expect(found.data).to eq @data
        end
        it 'finds the default using its start date' do
          found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234', @now)
          expect(found.data).to eq @other_data
        end
      end
    end
  end

  # ==========================================================================

  context 'list' do
    it '' do
    end
  end

end
