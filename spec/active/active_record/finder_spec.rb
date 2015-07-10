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

        acquire_with :uuid, :code

        # These forms follow quite closely the RDoc comments in
        # the finder.rb source.

        ARRAY_MATCH = Proc.new { | attr, value |
          [ { attr => [ value ].flatten } ]
        }

        # Pretend security scoping that only finds things with
        # a UUID and code coming in from the session, for secured
        # searches. Note intentional mix of Symbols and Strings.

        secure_with(
          'uuid' => :authorised_uuids, # Array
          :code => 'authorised_code'   # Single item
        )

        search_with(
          'field_one' => nil,
          :field_two => Proc.new { | attr, value |
            [ "#{ attr } ILIKE ?", value ]
          },
          :field_three => ARRAY_MATCH
        )

        filter_with(
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
    @c.code = 'C'
    @c.field_one = 'group 2'
    @c.field_two = 'two c'
    @c.field_three = 'three c'
    @c.save!
    @code = @c.code

    @list_params = Hoodoo::Services::Request::ListParameters.new
  end

  # ==========================================================================

  context 'acquire' do
    it 'finds from the class' do
      found = RSpecModelFinderTest.acquire( @id )
      expect( found ).to eq(@a)

      found = RSpecModelFinderTest.acquire( @uuid )
      expect( found ).to eq(@b)

      found = RSpecModelFinderTest.acquire( @code )
      expect( found ).to eq(@c)
    end

    it 'finds with a chain' do
      finder = RSpecModelFinderTest.where( :field_one => 'group 1' )

      found = finder.acquire( @id )
      expect( found ).to eq(@a)

      found = finder.acquire( @uuid )
      expect( found ).to eq(@b)

      found = finder.acquire( @code )
      expect( found ).to eq(nil) # Not in 'group 1'
    end
  end

  # ==========================================================================

  context 'acquire_in' do
    before :each do
      @scoped_1 = RSpecModelFinderTest.new
      @scoped_1.uuid        = 'uuid 1'
      @scoped_1.code        = 'code 1'
      @scoped_1.field_one = 'scoped 1'
      @scoped_1.save!

      @scoped_2 = RSpecModelFinderTest.new
      @scoped_2.uuid        = 'uuid 1'
      @scoped_2.code        = 'code 2'
      @scoped_2.field_one = 'scoped 2'
      @scoped_2.save!

      @scoped_3 = RSpecModelFinderTest.new
      @scoped_3.uuid        = 'uuid 2'
      @scoped_3.code        = 'code 2'
      @scoped_3.field_one = 'scoped 3'
      @scoped_3.save!

      # Get a good-enough-for-test interaction which has a context
      # that contains a Session we can modify.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    it 'finds with secure scopes from the class' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_1 )

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_code = 'code 2'

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_uuids = [ 'uuid 2' ]

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_3 )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_3 )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_1 )

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one + '!' ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_2.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]
      @session.scoping.authorised_code  = 'code 2'

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_2.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_3 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one + '!' ).acquire_in( @context )
      expect( found ).to be_nil
    end
  end

  # ==========================================================================

  context 'lists' do
    it 'lists with pages, offsets and counts' do
      @list_params.offset = 1 # 0 is first record
      @list_params.limit  = 1

      finder = RSpecModelFinderTest.order( :field_three => :asc ).list( @list_params )
      expect( finder ).to eq([@b])
      expect( finder.dataset_size).to eq(3)

      @list_params.offset = 1
      @list_params.limit  = 2

      finder = RSpecModelFinderTest.order( :field_three => :asc ).list( @list_params )
      expect( finder ).to eq([@b, @c])
      expect( finder.dataset_size).to eq(3)
    end
  end

  # ==========================================================================

  context 'search' do
    it 'searches without chain' do
      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c, @a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])
    end

    it 'searches with chain' do
      constraint = RSpecModelFinderTest.where( :field_one => 'group 1' )

      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])
    end
  end

  # ==========================================================================

  context 'filter' do
    it 'filters without chain' do
      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c, @b])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b])
    end

    it 'filters with chain' do

      # Remember, the constraint is *inclusive* unlike all the
      # subsequent filters which *exclude*.

      constraint = RSpecModelFinderTest.where( :field_one => 'group 2' )

      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])
    end
  end

  # ==========================================================================

  context 'list_in' do
    before :each do
      @scoped_1 = RSpecModelFinderTest.new
      @scoped_1.uuid = 'uuid 1'
      @scoped_1.code = 'code 1'
      @scoped_1.field_one = 'scoped 1'
      @scoped_1.save!

      @scoped_2 = RSpecModelFinderTest.new
      @scoped_2.uuid = 'uuid 1'
      @scoped_2.code = 'code 2'
      @scoped_2.field_one = 'scoped 2'
      @scoped_2.save!

      @scoped_3 = RSpecModelFinderTest.new
      @scoped_3.uuid = 'uuid 2'
      @scoped_3.code = 'code 2'
      @scoped_3.field_one = 'scoped 3'
      @scoped_3.save!

      # Get a good-enough-for-test interaction which has a context
      # that contains a Session we can modify.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    it 'lists with secure scopes from the class' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_1 ] )

      @session.scoping.authorised_code = 'code 2'

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_2 ] )

      @session.scoping.authorised_uuids = [ 'uuid 2' ]

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_3 ] )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]

      # OK, so these test 'with a chain' too... It's just convenient to (re-)cover
      # that aspect here.

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'asc' )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'desc' )
      expect( list ).to eq( [ @scoped_3, @scoped_2 ] )

      list = RSpecModelFinderTest.reorder( 'field_one' => 'asc' ).list_in( @context )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.reorder( 'field_one' => 'desc' ).list_in( @context )
      expect( list ).to eq( [ @scoped_3, @scoped_2 ] )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      list = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).list_in( @context )
      expect( list ).to eq( [ @scoped_1 ] )

      list = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one + '!' ).list_in( @context )
      expect( list ).to eq( [] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => @scoped_1.field_one )
      expect( list ).to eq( [ @scoped_1 ] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => @scoped_1.field_one + '!' )
      expect( list ).to eq( [] )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]
      @session.scoping.authorised_code  = 'code 2'

      list = RSpecModelFinderTest.where( :field_one => [ @scoped_1.field_one, @scoped_2.field_one ] ).list_in( @context )
      expect( list ).to eq( [ @scoped_2 ] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => [ @scoped_1.field_one, @scoped_2.field_one ] )
      expect( list ).to eq( [ @scoped_2 ] )

      list = RSpecModelFinderTest.where( :field_one => [ @scoped_2.field_one, @scoped_3.field_one ] ).list_in( @context ).reorder( 'field_one' => 'asc' )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'asc' ).where( :field_one => [ @scoped_2.field_one, @scoped_3.field_one ] )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )
    end
  end

  # ==========================================================================

  context 'deprecated' do
    it '#polymorphic_find calls #acquire' do
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :acquire ).once.with( 21 )
      RSpecModelFinderTest.polymorphic_find( RSpecModelFinderTest, 21 )
    end

    it '#polymorphic_id_fields calls #acquire_with' do
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :acquire_with ).once.with( :uuid, :code )
      RSpecModelFinderTest.polymorphic_id_fields( :uuid, :code )
    end

    it '#list_finder calls #list' do
      params = { :search => { :field_one => 'one' } }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :list ).once.with( params )
      RSpecModelFinderTest.list_finder( params )
    end

    it '#list_search_map calls #search_with' do
      params = { :foo => nil, :bar => nil }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :search_with ).once.with( params )
      RSpecModelFinderTest.list_search_map( params )
    end

    it '#list_filter_map calls #filter_with' do
      params = { :foo => nil, :bar => nil }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :filter_with ).once.with( params )
      RSpecModelFinderTest.list_filter_map( params )
    end
  end
end
