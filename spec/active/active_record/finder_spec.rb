require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Finder do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_finder_tests ) do | t |
        t.text :uuid
        t.text :code
        t.text :field_one
        t.text :field_two
        t.text :field_three

        t.timestamps
      end

      class RSpecModelFinderTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Finder

        polymorphic_id_fields :uuid, :code

        # These forms follow quite closely the RDoc comments in
        # the finder.rb source.

        ARRAY_MATCH = Proc.new { | attr, value |
          [ { attr => [ value ].flatten } ]
        }

        # Deliberate mixture of symbols and strings. No ILIKE
        # in SQLite, so just use LIKE. It's case insensitive by
        # default anyway.

        list_search_map(
          'field_one' => nil,
          :field_two => Proc.new { | attr, value |
            [ "#{ attr } LIKE ?", value ]
          },
          :field_three => ARRAY_MATCH
        )

        list_filter_map(
          :field_one => ARRAY_MATCH,
          :field_two => nil,
          'field_three' => Proc.new { | attr, value |
            [ "#{ attr } LIKE ?", value ]
          }
        )
      end
    end
  end

  before :each do
    @a = RSpecModelFinderTest.new
    @a.id = 1
    @a.field_one = 'group 1'
    @a.field_two = 'two a'
    @a.field_three = 'three a'
    @a.save!
    @id = @a.id

    @b = RSpecModelFinderTest.new
    @b.uuid = Hoodoo::UUID.generate
    @b.field_one = 'group 1'
    @b.field_two = 'two b'
    @b.field_three = 'three b'
    @b.save!
    @uuid = @b.uuid

    @c = RSpecModelFinderTest.new
    @c.code = "C"
    @c.field_one = 'group 2'
    @c.field_two = 'two c'
    @c.field_three = 'three c'
    @c.save!
    @code = @c.code

    @list_params = Hoodoo::ServiceRequest::ListParameters.new
  end

  # ==========================================================================

  context 'polymorphic find' do
    it 'finds from the class' do
      found = RSpecModelFinderTest.polymorphic_find( RSpecModelFinderTest, @id )
      expect( found ).to eq(@a)

      found = RSpecModelFinderTest.polymorphic_find( RSpecModelFinderTest, @uuid )
      expect( found ).to eq(@b)

      found = RSpecModelFinderTest.polymorphic_find( RSpecModelFinderTest, @code )
      expect( found ).to eq(@c)
    end

    it 'finds with a chain' do
      finder = RSpecModelFinderTest.where( :field_one => 'group 1' )

      found = RSpecModelFinderTest.polymorphic_find( finder, @id )
      expect( found ).to eq(@a)

      found = RSpecModelFinderTest.polymorphic_find( finder, @uuid )
      expect( found ).to eq(@b)

      found = RSpecModelFinderTest.polymorphic_find( finder, @code )
      expect( found ).to eq(nil) # Not in 'group 1'
    end
  end

  # ==========================================================================

  context 'search' do
    it 'searches without chain' do
      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@c])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@c, @a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@c])
    end

    it 'searches with chain' do
      constraint = RSpecModelFinderTest.where( :field_one => 'group 1' )

      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])
    end
  end

  # ==========================================================================

  context 'filter' do
    it 'filters without chain' do
      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@c, @b])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = RSpecModelFinderTest.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@b])
    end

    it 'filters with chain' do

      # Remember, the constraint is *inclusive* unlike all the
      # subsequent filters which *exclude*.

      constraint = RSpecModelFinderTest.where( :field_one => 'group 2' )

      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([@c])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = constraint.list_finder( @list_params )
      expect( finder.all.to_a ).to eq([])
    end
  end
end
