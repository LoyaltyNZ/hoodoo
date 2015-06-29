require 'byebug'
require 'spec_helper'
require 'active_record'
require 'timecop'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests, :id => false ) do | t |
        t.string   :uuid,            :null => false
        t.string   :activerecord_id, :null => false
        t.text     :data
        t.datetime :effective_start, :null => false
        t.datetime :effective_end
        # t.tsrange  :effective_date_range # default tsrange(now()::timestamp, 'infinity', '[)') not null
        t.timestamps
      end
      class RSpecModelEffectiveDateTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_field_override_tests, :id => false ) do | t |
        t.text     :uuid,       :null => false
        t.string   :model_id,   :null => false
        t.text     :data
        t.datetime :valid_from, :null => false
        t.datetime :valid_until
        # t.tsrange  :effective_date_range # default tsrange(now()::timestamp, 'infinity', '[)') not null
        t.timestamps
      end
      class RSpecModelEffectiveDateFieldOverrideTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate

        effective_date_start_field :valid_from
        effective_date_end_field :valid_until
      end
    end
  end

  before :each do
    @a = RSpecModelEffectiveDateTest.new
    @b = RSpecModelEffectiveDateTest.new

    @data = 'some data'
    @other_data = 'some other data'
    @now = Time.now
  end

  context 'persisting an ActiveRecord model' do
    it 'sets the correct activerecord_id value' do

      @a.uuid = Hoodoo::UUID.generate
      @a.save!

      found = RSpecModelEffectiveDateTest.find_at(@a.uuid)

      expected_activerecord_id = @a.uuid +
        "_" +
        Hoodoo::ActiveRecord::EffectiveDate.time_to_s_with_large_precision(
          @a.effective_start
        )

      expect(found.activerecord_id).to eq(expected_activerecord_id)

    end

    it 'creates a new record when updating' do

      @a.uuid = Hoodoo::UUID.generate
      @a.data = 'original data'
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(1)

      @a.data = 'modified data'
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(2)

      @a.data = 'more modified data'
      @a.save!
      expect(RSpecModelEffectiveDateTest.count).to eq(3)

      # Check all the data is there
      expect(RSpecModelEffectiveDateTest.pluck(:data)).
        to match_array([
          'original data',
          'modified data',
          'more modified data'
      ])
    end
  end

  context 'persisting a Hoodoo::ActiveRecord model' do
    class RSpecModelEffectiveDateTestHoodoo < Hoodoo::ActiveRecord::Base
      include Hoodoo::ActiveRecord::EffectiveDate
      self.table_name = 'r_spec_model_effective_date_tests'

      self.primary_key = :activerecord_id

      def self.uuid_column
        :uuid
      end
    end

    it 'sets the correct id value' do

      hoodoo_model = RSpecModelEffectiveDateTestHoodoo.new
      hoodoo_model.save!

      found = RSpecModelEffectiveDateTest.find_at(hoodoo_model.uuid)

      expected_activerecord_id = found.uuid +
        "_" +
        Hoodoo::ActiveRecord::EffectiveDate.time_to_s_with_large_precision(
          found.effective_start
        )

      expect(found.activerecord_id).to eq(expected_activerecord_id)
    end

    it 'creates a new record when updating' do
      hoodoo_model = RSpecModelEffectiveDateTestHoodoo.new

      hoodoo_model.data = 'original data'
      hoodoo_model.save!

      expect(RSpecModelEffectiveDateTestHoodoo.count).to eq(1)

      hoodoo_model.data = 'modified data'
      hoodoo_model.save!
      expect(RSpecModelEffectiveDateTestHoodoo.count).to eq(2)
    end
  end

  context 'find_at' do
    it 'finds a default record' do
      @a.data = @data
      @a.uuid = '1234'
      @a.save

      found = RSpecModelEffectiveDateTest.find_at('1234')
      expect(found.data).to eq @data
    end

    it 'finds an end dated record' do
      @a.data = @data
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
        @a.save

        @b.data = @other_data
        @b.effective_start = @now
        @b.uuid = '1234'
        @b.save
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
        @d.uuid = '1234'
        @d.save

        found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234')
        expect(found.data).to eq @data
      end

      it 'finds an end dated record' do
        @d.data = @data
        @d.uuid = '1234'
        @d.valid_until = Time.now + 3.days
        @d.save

        found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234')
        expect(found.data).to eq @data
      end

      context "with many existing records" do
        before do
          @d.data = @data
          @d.uuid = '1234'
          @d.valid_from = @now - 3.days
          @d.valid_until = @now
          @d.save

          @e.data = @other_data
          @e.valid_from = @now
          @e.uuid = '1234'
          @e.save
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
