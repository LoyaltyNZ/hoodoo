require 'spec_helper'
require 'active_record'
require 'timecop'

describe Hoodoo::ActiveRecord::EffectiveDate do
  before :all do
    spec_helper_silence_stdout() do

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_tests, :id => false ) do | t |
        t.text :id,  :null => false
        t.text :data
        t.timestamps
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_test_history_entries, :id => false ) do | t |
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

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_test_overrides, :id => false ) do | t |
        t.text :activerecord_id,  :null => false
        t.text :data
        t.timestamps
      end

      ActiveRecord::Migration.create_table( :r_spec_model_effective_date_history_entries, :id => false ) do | t |
        t.text     :id,            :null => false
        t.text     :uuid,          :null => false
        t.text     :data
        t.datetime :effective_end, :null => false
        t.timestamps
      end

      class RSpecModelEffectiveDateTestOverride < ActiveRecord::Base
        include Hoodoo::ActiveRecord::EffectiveDate
        self.primary_key                  = :activerecord_id
        self.effective_date_history_table = :r_spec_model_effective_date_history_entries
      end
    end
  end

  context "using default effective dating config" do

    before(:all) do

      # Create some examples data for finding. The data has two different UUIDs
      # which I'll referer to as A and B. The following tables contain the
      # historical and current records separately with their attributes.
      #
      # Historical:
      # ------------------------------------------------
      #  uuid | data    | created_at    | effective_end
      # ------------------------------------------------
      #  A    | "one"   | now - 5 hours | now - 3 hours
      #  B    | "two"   | now - 4 hours | now - 2 hours
      #  A    | "three" | now - 3 hours | now - 1 hour
      #  B    | "four"  | now - 2 hours | now
      #
      # Current:
      # ------------------------------
      #  uuid | data   | created_at
      # ------------------------------
      #  B    | "five" | now - 1 hour
      #  A    | "six"  | now
      #

      @uuid_a = Hoodoo::UUID.generate
      @uuid_b = Hoodoo::UUID.generate

      @now  = Time.now.utc

      # uuid, data, created_at, effective_at
      [
        [ @uuid_a, "one",   @now - 5.hours, @now - 3.hours ],
        [ @uuid_b, "two",   @now - 4.hours, @now - 2.hours ],
        [ @uuid_a, "three", @now - 3.hours, @now - 1.hour ],
        [ @uuid_b, "four",  @now - 2.hours, @now ]
      ].each do | row_data |
        RSpecModelEffectiveDateTestHistoryEntry.new({
          :id            => row_data[0] + "-" + row_data[3].iso8601,
          :uuid          => row_data[0],
          :data          => row_data[1],
          :created_at    => row_data[2],
          :effective_end => row_data[3]
        }).save!
      end

      # uuid, data, created_at
      [
        [ @uuid_b, "five", @now - 1.hour ],
        [ @uuid_a, "six", @now ]
      ].each do | row_data |
        RSpecModelEffectiveDateTest.new({
          :id         => row_data[0],
          :data       => row_data[1],
          :created_at => row_data[2]
        }).save!
      end

    end

    context 'find_at' do

      def test_expectation(uuid, time, expected_data)
        expect(RSpecModelEffectiveDateTest.find_at(uuid, time).try(:data)).
          to eq(expected_data)
      end

      it 'finds current records' do

        test_expectation(@uuid_b, @now, "five")
        test_expectation(@uuid_a, @now, "six")

      end

      it 'finds no record where there are gaps' do

        test_expectation(@uuid_a, @now - 1.hour, nil)

      end

      it 'finds past records' do

        test_expectation(@uuid_b, @now - 2.hours, "four")
        test_expectation(@uuid_a, @now - 3.hours, "three")
        test_expectation(@uuid_b, @now - 3.hours, "two")
        test_expectation(@uuid_a, @now - 4.hours, "one")

      end

      it 'finds no record before any were created with that UUID' do

        test_expectation(@uuid_a, @now - 10.hours, nil)
        test_expectation(@uuid_b, @now - 10.hours, nil)

      end

    end

    context 'list_at' do

      def test_expectation(time, expected_data)
        expect(RSpecModelEffectiveDateTest.list_at(time).pluck(:data)).
          to match_array(expected_data)
      end

      it 'returns no records before any were effective' do
        test_expectation(@now - 10.hours, [])
      end

      it 'returns records that used to be effective starting at past time' do
        test_expectation(@now - 5.hours, ["one"])
        test_expectation(@now - 4.hours, ["one", "two"])
        test_expectation(@now - 3.hours, ["two", "three"])
        test_expectation(@now - 2.hours, ["three", "four"])
        test_expectation(@now - 1.hour,  ["four", "five"])
      end

      it 'returns records that are effective now' do
        test_expectation(@now, ["five", "six"])
      end

      it 'works with further filtering' do
        expect(RSpecModelEffectiveDateTest.list_at(@now).where(:id => @uuid_a).pluck(:data)).
          to eq(["six"])
      end

    end
  end

  context "overriding primary key name and history table name" do

    before(:all) do

      # Create some examples data for finding. The data has two different UUIDs
      # which I'll referer to as A and B. The following tables contain the
      # historical and current records separately with their attributes.
      #
      # Historical:
      # ------------------------------------------------
      #  uuid | data    | created_at    | effective_end
      # ------------------------------------------------
      #  A    | "one"   | now - 5 hours | now - 3 hours
      #  B    | "two"   | now - 4 hours | now - 2 hours
      #  A    | "three" | now - 3 hours | now - 1 hour
      #  B    | "four"  | now - 2 hours | now
      #
      # Current:
      # -----------------------------------------
      #  activerecord_id | data   | created_at
      # -----------------------------------------
      #  B               | "five" | now - 1 hour
      #  A               | "six"  | now
      #

      @uuid_a = Hoodoo::UUID.generate
      @uuid_b = Hoodoo::UUID.generate

      @now  = Time.now.utc

      # uuid, data, created_at, effective_at
      [
        [ @uuid_a, "one",   @now - 5.hours, @now - 3.hours ],
        [ @uuid_b, "two",   @now - 4.hours, @now - 2.hours ],
        [ @uuid_a, "three", @now - 3.hours, @now - 1.hour ],
        [ @uuid_b, "four",  @now - 2.hours, @now ]
      ].each do | row_data |
        RSpecModelEffectiveDateTestOverrideHistoryEntry.new({
          :id            => row_data[0] + "-" + row_data[3].iso8601,
          :uuid          => row_data[0],
          :data          => row_data[1],
          :created_at    => row_data[2],
          :effective_end => row_data[3]
        }).save!
      end

      # uuid, data, created_at
      [
        [ @uuid_b, "five", @now - 1.hour ],
        [ @uuid_a, "six", @now ]
      ].each do | row_data |
        RSpecModelEffectiveDateTestOverride.new({
          :id         => row_data[0],
          :data       => row_data[1],
          :created_at => row_data[2]
        }).save!
      end

    end

    context 'find_at' do

      def test_expectation(uuid, time, expected_data)
        expect(RSpecModelEffectiveDateTestOverride.find_at(uuid, time).try(:data)).
          to eq(expected_data)
      end

      it 'finds current records' do

        test_expectation(@uuid_b, @now, "five")
        test_expectation(@uuid_a, @now, "six")

      end

      it 'finds no record where there are gaps' do

        test_expectation(@uuid_a, @now - 1.hour, nil)

      end

      it 'finds past records' do

        test_expectation(@uuid_b, @now - 2.hours, "four")
        test_expectation(@uuid_a, @now - 3.hours, "three")
        test_expectation(@uuid_b, @now - 3.hours, "two")
        test_expectation(@uuid_a, @now - 4.hours, "one")

      end

      it 'finds no record before any were created with that UUID' do

        test_expectation(@uuid_a, @now - 10.hours, nil)
        test_expectation(@uuid_b, @now - 10.hours, nil)

      end

    end

    context 'list_at' do

      def test_expectation(time, expected_data)
        expect(RSpecModelEffectiveDateTestOverride.list_at(time).pluck(:data)).
          to match_array(expected_data)
      end

      it 'returns no records before any were effective' do
        test_expectation(@now - 10.hours, [])
      end

      it 'returns records that used to be effective starting at past time' do
        test_expectation(@now - 5.hours, ["one"])
        test_expectation(@now - 4.hours, ["one", "two"])
        test_expectation(@now - 3.hours, ["two", "three"])
        test_expectation(@now - 2.hours, ["three", "four"])
        test_expectation(@now - 1.hour,  ["four", "five"])
      end

      it 'returns records that are effective now' do
        test_expectation(@now, ["five", "six"])
      end

      it 'works with further filtering' do
        found = RSpecModelEffectiveDateTestOverride.list_at(@now).
          where(:activerecord_id => @uuid_a)
        expect(found.pluck(:data)).to eq(["six"])
      end

    end

  end

end
