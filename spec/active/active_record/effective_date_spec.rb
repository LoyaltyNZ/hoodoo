require 'byebug'
require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests ) do | t |
        t.string   :uuid
        t.text     :data
        t.datetime :effective_start
        t.datetime :effective_end
        # t.tsrange  :effective_date_range # default tsrange(now()::timestamp, 'infinity', '[)') not null
        t.timestamps
      end
      class RSpecModelEffectiveDateTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_field_override_tests ) do | t |
        t.string   :uuid
        t.text     :data
        t.datetime :valid_from
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
