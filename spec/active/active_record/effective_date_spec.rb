require 'byebug'
require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    spec_helper_silence_stdout() do
      CREATE_TIMESTAMP = 'DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP'
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
    end
  end

  before :each do
    @a = RSpecModelEffectiveDateTest.new
    @b = RSpecModelEffectiveDateTest.new
    @c = RSpecModelEffectiveDateTest.new

    @data = 'some data'
    @other_data = 'some other data'
    @now = Time.now
  end

  # ==========================================================================

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
  end

  # ==========================================================================

  context 'list' do
    it '' do
    end
  end

end
