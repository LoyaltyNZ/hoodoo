require 'byebug'
require 'spec_helper'
require 'active_record'
require 'timecop'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    # spec_helper_silence_stdout() do

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests, :id => false ) do | t |
        t.text :id,  :null => false
        t.text :data
        t.timestamps
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests_history_entries, :id => false ) do | t |
        t.text     :id,            :null => false
        t.text     :uuid,          :null => false
        t.text     :data
        t.datetime :effective_end, :null => false
        t.timestamps
      end

      class RSpecModelEffectiveDateTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
        self.primary_key = :id
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_field_override_tests, :id => false ) do | t |
        t.text     :unique_id,  :null => false
        t.text     :data
        # t.datetime :valid_from, :null => false
        # t.datetime :valid_until
        t.timestamps
      end

      class RSpecModelEffectiveDateFieldOverrideTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate

        self.effective_date_history_table = :r_spec_model_history
        self.effective_date_start_column  = :valid_from
        self.effective_date_end_column    = :valid_until
      end
    # end
  end

  context 'find_at' do

    context 'with one effective record and one historical record' do

      before(:all) do
        @uuid = Hoodoo::UUID.generate
        @now  = Time.now.utc

        @old_data = 'old data'
        @new_data = 'new data'

        @old_record = RSpecModelEffectiveDateTestHistoryEntry.new({
          :id            => @uuid + "_" + @now.iso8601,
          :uuid          => @uuid,
          :data          => @old_data,
          :effective_end => @now
        })
        @old_record.save!( :validate => false )
        @new_record = RSpecModelEffectiveDateTest.create({
          :id   => @uuid,
          :data => @new_data
        })
      end

      it 'finds the effective record' do

        found = RSpecModelEffectiveDateTest.find_at(@uuid)
        expect(found.data).to eq @new_data

      end

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
        it 'finds none when there are no records effective when specified' do
          found = RSpecModelEffectiveDateFieldOverrideTest.find_at('1234', @now - 1.year)
          expect(found).to eq nil
        end
      end
    end
  end

  # ==========================================================================

  context 'list' do
    before do
      # No longer effective
      @d = RSpecModelEffectiveDateTest.new
      @d.data = 'first data'
      @d.uuid = '1234'
      @d.effective_start = @now - 3.days
      @d.effective_end = @now
      @d.save!

      # Effective from now on
      @e = RSpecModelEffectiveDateTest.new
      @e.data = 'second data'
      @e.uuid = '1234'
      @e.effective_start = @now
      @e.save!

      # Effective from now for three days
      @f = RSpecModelEffectiveDateTest.new
      @f.data = 'third data'
      @f.uuid = '5678'
      @f.effective_start = @now
      @f.effective_end = @now + 3.days
      @f.save!

      # Not effective for three more days
      @g = RSpecModelEffectiveDateTest.new
      @g.data = 'fourth data'
      @g.uuid = '5678'
      @g.effective_start = @now + 3.days
      @g.save!
    end

    it 'returns records that used to be effective starting at past time' do
      expect(RSpecModelEffectiveDateTest.list_at(@now - 3.days).pluck(:data)).
        to match_array([@d.data])
    end

    it 'returns records that used to be effective at past time' do
      expect(RSpecModelEffectiveDateTest.list_at(@now - 2.days).pluck(:data)).
        to match_array([@d.data])
    end

    it 'returns records effective now with no parameters to list_at' do
      expect(RSpecModelEffectiveDateTest.list_at.pluck(:data)).
        to match_array([@e.data, @f.data])
    end

    it 'returns records that will be effective starting at future time' do
      expect(RSpecModelEffectiveDateTest.list_at(@now + 3.days).pluck(:data)).
        to match_array([@e.data, @g.data])
    end

    it 'returns records that will be effective at future time' do
      expect(RSpecModelEffectiveDateTest.list_at(@now + 1.year).pluck(:data)).
        to match_array([@e.data, @g.data])
    end

    it 'returns no results for a time when no records were effective' do
      expect(RSpecModelEffectiveDateTest.list_at(@now - 1.year).pluck(:data)).
        to eq([])
    end

  end

end
