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
    it 'records path components properly' do
      ary = [ 'one', 'two', 'three' ]
      @r.uri_path_components = ary

      expect(@r.uri_path_components).to eq(ary)
      expect(@r.ident).to eq(ary.first)
    end

    it 'deals with nil path components properly' do
      ary = nil
      @r.uri_path_components = ary

      expect(@r.uri_path_components).to be_nil
      expect(@r.ident).to be_nil
    end

    it 'deals with non-array path components properly' do
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

  context '#list' do
    it 'has correct default values' do
      expect( @r.list.offset      ).to eq( 0                          )
      expect( @r.list.limit       ).to eq( 50                         )
      expect( @r.list.sort_data   ).to eq( { 'created_at' => 'desc' } )
      expect( @r.list.search_data ).to eq( {}                         )
      expect( @r.list.filter_data ).to eq( {}                         )
    end

    context 'and hashes via' do
      before :each do
        @offset = 1000
        @limit  = 500
        @sort   = { 'created_at' => 'asc' }
        @search = { 'foo' => 'bar', 'bar' => { 'baz' => 3 } }
        @filter = { 'bar' => 'foo', 'baz' => { 'bar' => 2 } }

        @replacement_hash = {
          'offset'      => @offset,
          'limit'       => @limit,
          'sort_data'   => @sort,
          'search_data' => @search,
          'filter_data' => @filter
        }
      end

      context '#to_h' do
        before :each do
          @r.list.offset      = @offset
          @r.list.limit       = @limit
          @r.list.sort_data   = @sort
          @r.list.search_data = @search
          @r.list.filter_data = @filter
        end

        it 'returns the expected Hash' do
          expect( @r.list.to_h ).to eq( @replacement_hash )
        end

        it 'deep-duplicates the parameters' do
          result = @r.list.to_h()

          old_sort_value = @sort[ @sort.keys.first ]
          result[ 'sort_data' ][ @sort.keys.first ] == 'changed'
          expect( @sort[ @sort.keys.first ] ).to eql( old_sort_value )

          old_search_value = @search[ @search.keys.first ]
          result[ 'search_data' ][ @search.keys.first ] == 'changed'
          expect( @search[ @search.keys.first ] ).to eql( old_search_value )

          old_filter_value = @filter[ @filter.keys.first ]
          result[ 'filter_data' ][ @filter.keys.first ] == 'changed'
          expect( @filter[ @filter.keys.first ] ).to eql( old_filter_value )
        end
      end

      context '#from_h!' do
        it 'overwrites all parameters' do
          request = Hoodoo::Services::Request.new

          expect( request.list.offset      ).to eq( 0                          )
          expect( request.list.limit       ).to eq( 50                         )
          expect( request.list.sort_data   ).to eq( { 'created_at' => 'desc' } )
          expect( request.list.search_data ).to eq( {}                         )
          expect( request.list.filter_data ).to eq( {}                         )

          request.list.from_h!( @replacement_hash )

          expect( request.list.offset      ).to eq( @offset )
          expect( request.list.limit       ).to eq( @limit  )
          expect( request.list.sort_data   ).to eq( @sort   )
          expect( request.list.search_data ).to eq( @search )
          expect( request.list.filter_data ).to eq( @filter )
        end

        it 'overwrites only provided parameters' do
          replacements = {
            'offset'      => @offset,
            'limit'       => @limit,
            'sort_data'   => @sort,
            'search_data' => @search,
            'filter_data' => @filter
          }

          # Iterate over all the possible keys above and build a Hash that
          # contains just one at a time. Make a new request, set the list
          # options from the one-at-a-time Hash and verify that only that
          # one parameter changed.

          replacements.each do | replacement_key, replacement_value |
            request = Hoodoo::Services::Request.new
            clean   = {
              'offset'      => request.list.offset,
              'limit'       => request.list.limit,
              'sort_data'   => request.list.sort_data,
              'search_data' => request.list.search_data,
              'filter_data' => request.list.filter_data
            }

            hash = { replacement_key => replacement_value }
            request.list.from_h!( hash )

            clean.each do | clean_key, clean_value |
              if clean_key == replacement_key
                expect( request.list.send( clean_key ) ).to eql( replacement_value )
              else
                expect( request.list.send( clean_key ) ).to eql( clean_value )
              end
            end
          end
        end
      end

      context '#to_h and #from_h! together' do
        before :each do
          @r.list.offset      = @offset
          @r.list.limit       = @limit
          @r.list.sort_data   = @sort
          @r.list.search_data = @search
          @r.list.filter_data = @filter
        end

        it 'translates from one list to another' do
          hash = @r.list.to_h

          request = Hoodoo::Services::Request.new
          request.list.from_h!( hash )

          expect( request.list.to_h ).to eql( @replacement_hash )
        end
      end
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
