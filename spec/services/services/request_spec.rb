require 'spec_helper'

describe Hoodoo::Services::Request do
  before do
    @r = Hoodoo::Services::Request.new
  end

  it 'has correct default values' do

    # For list parameters in @r.list, see later.
    #
    expect( @r.locale              ).to eq( 'en-nz' )
    expect( @r.dated_at            ).to eq( nil     )
    expect( @r.body                ).to eq( nil     )
    expect( @r.uri_path_components ).to eq( []      )
    expect( @r.ident               ).to eq( nil     )
    expect( @r.uri_path_extension  ).to eq( ''      )
    expect( @r.embeds              ).to eq( []      )
    expect( @r.references          ).to eq( []      )
    expect( @r.headers             ).to eq( {}      )

    expect( @r.headers.frozen? ).to eq( true )

  end

  context 'uri_path_components' do
    it 'should record path components properly' do
      ary = [ 'one', 'two', 'three' ]
      @r.uri_path_components = ary

      expect(@r.uri_path_components).to eq(ary)
      expect(@r.ident).to eq(ary.first)
    end

    it 'should deal with nil path components properly' do
      ary = nil
      @r.uri_path_components = ary

      expect(@r.uri_path_components).to be_nil
      expect(@r.ident).to be_nil
    end

    it 'should deal with non-array path components properly' do
      ary = 'not an array'
      @r.uri_path_components = ary

      expect(@r.uri_path_components).to be_nil
      expect(@r.ident).to be_nil
    end
  end

  it 'rationalises date/time' do
    [ :dated_at, :dated_from ].each do | attr |
      now = DateTime.now
      @r.send( "#{ attr }=", now )
      expect( @r.send( attr ) ).to eq( now )

      now = DateTime.now + 10
      @r.send( "#{ attr }=", now.to_time )
      expect( @r.send( attr ) ).to eq( now )

      now = DateTime.now + 20
      @r.send( "#{ attr }=", Hoodoo::Utilities::nanosecond_iso8601( now ) )
      expect( @r.send( attr ) ).to eq( now )
    end
  end

  context 'list parameters' do
    it 'have correct default values' do
      expect( @r.list.offset         ).to eq( 0                          )
      expect( @r.list.limit          ).to eq( 50                         )
      expect( @r.list.sort_data      ).to eq( { 'created_at' => 'desc' } )
      expect( @r.list.search_data    ).to eq( {}                         )
      expect( @r.list.filter_data    ).to eq( {}                         )
    end

    it 'can be returned as a Hash' do
      sort   = { 'created_at' => 'asc' }
      search = { 'foo' => 'bar', 'bar' => { 'baz' => 3 } }
      filter = { 'bar' => 'foo', 'baz' => { 'bar' => 2 } }

      @r.list.offset      = 1000
      @r.list.limit       = 500
      @r.list.sort_data   = sort
      @r.list.search_data = search
      @r.list.filter_data = filter

      expect( @r.list.to_h ).to eq( {
        'offset'      => 1000,
        'limit'       => 500,
        'sort_data'   => sort,
        'search_data' => search,
        'filter_data' => filter
      } )

      # TODO: Extra checks to do:
      #
      # * Prove deep-dup by modifying search data in to_h response and
      #   confirming that 'sort'/'search'/'filter' are not changed.
      #
      # * Prove we can load a generated Hash into a *new* instance and
      #   get an object that matches the original.

    end

    it 'can be loaded into instance as a Hash' do

      # TODO:
      # @r.list.from_h!( ... )

    end

    it 'supports deprecated accessors' do
      lo = 10
      ll = 20
      ke = 'foo'
      di = 'asc'
      sd = { :foo => :bar }
      fd = { :baz => :foo }

      @r.list_offset         = lo
      @r.list_limit          = ll
      @r.list_sort_data      = { ke => di }
      @r.list_search_data    = sd
      @r.list_filter_data    = fd

      expect( @r.list_offset         ).to eq( lo           )
      expect( @r.list_limit          ).to eq( ll           )
      expect( @r.list_sort_data      ).to eq( { ke => di } )
      expect( @r.list_search_data    ).to eq( sd           )
      expect( @r.list_filter_data    ).to eq( fd           )
    end
  end
end
