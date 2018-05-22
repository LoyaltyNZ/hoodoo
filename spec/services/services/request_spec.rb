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

  # ==========================================================================

  # Used for #list sub-tests around "#from_h!", where we want to ensure that
  # a Hash containing less-than-all possible keys results in updates to just
  # the relevant attributes of the target object.
  #
  # Provide a Hash of *attribute* key-value pairs for new values to assign,
  # except for the special cases of Arrays in 'sort' and 'direction', which
  # are mapped to the 'sort_data' Hash.
  #
  # Iterates over all the possible keys above and builds a Hash that contains
  # just one at a time. Makes a new Request, sets the list options from the
  # one-at-a-time Hash and verifies that only the one parameter changed.
  #
  # A little fiddly due to the name mappings "search"/"search_data" or
  # "filter"/"filter_data" and the unpacking of "sort_data" into independently
  # alterable "sort" and "direction" lists. Tests sort/direction flattening of
  # single element arrays into simple types in passing.
  #
  def test_replacements( replacements )
    replacements.each do | replacement_key, replacement_value |
      request = Hoodoo::Services::Request.new
      clean   = {
        'offset'      => request.list.offset,
        'limit'       => request.list.limit,
        'sort_data'   => request.list.sort_data,
        'search_data' => request.list.search_data,
        'filter_data' => request.list.filter_data
      }

      from_h_key = case replacement_key
        when 'search_data'
          'search'
        when 'filter_data'
          'filter'
        else
          replacement_key
      end

      hash = { from_h_key => replacement_value }
      request.list.from_h!( hash )

      clean.each do | clean_key, clean_value |
        expected_value = replacement_value # Makes code below easier to read

        if clean_key == 'sort_data' && replacement_key == 'sort'
          # In passing, test 1-element-array flattening...
          expected_value = expected_value.first if expected_value.is_a?( Array ) && expected_value.count == 1
          expect( request.list.send( clean_key ) ).to eql( { expected_value => clean_value.values.first } )

        elsif clean_key == 'sort_data' && replacement_key == 'direction'
          expected_value = expected_value.first if expected_value.is_a?( Array ) && expected_value.count == 1
          expect( request.list.send( clean_key ) ).to eql( { clean_value.keys.first => expected_value } )

        elsif clean_key == replacement_key
          expect( request.list.send( clean_key ) ).to eql( expected_value )

        else
          expect( request.list.send( clean_key ) ).to eql( clean_value )

        end
      end
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

    # ========================================================================

    context 'with a single sort key and direction' do
      context 'and via' do
        before :each do
          @offset = 1000
          @limit  = 500
          @sort   = { 'new_sort' => 'asc' }
          @search = { 'foo' => 'bar', 'bar' => { 'baz' => 3 } }
          @filter = { 'bar' => 'foo', 'baz' => { 'bar' => 2 } }

          @replacement_hash = {
            'offset'    => @offset,
            'limit'     => @limit,
            'sort'      => @sort.keys.first,
            'direction' => @sort.values.first,
            'search'    => @search,
            'filter'    => @filter
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

            old_search_value = @search.values.first
            result[ 'search' ][ @search.keys.first ] = 'changed'
            expect( @search.values.first ).to eql( old_search_value )

            old_filter_value = @filter.values.first
            result[ 'filter' ][ @filter.keys.first ] = 'changed'
            expect( @filter.values.first ).to eql( old_filter_value )
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
            test_replacements( {
              'offset'      => @offset,
              'limit'       => @limit,
              'sort'        => @sort.keys.first,
              'direction'   => @sort.values.first,
              'search_data' => @search,
              'filter_data' => @filter
            } )
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
    end

    # ========================================================================

    context 'with multiple sort keys and directions' do
      context 'and via' do
        before :each do
          @offset = 1000
          @limit  = 500
          @sort   = { 'new_sort' => 'asc', 'another_new_sort' => 'asc' }
          @search = { 'foo' => 'bar', 'bar' => { 'baz' => 3 } }
          @filter = { 'bar' => 'foo', 'baz' => { 'bar' => 2 } }

          @replacement_hash = {
            'offset'    => @offset,
            'limit'     => @limit,
            'sort'      => @sort.keys,
            'direction' => @sort.values,
            'search'    => @search,
            'filter'    => @filter
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

            old_sort_key = @sort.keys.first
            result[ 'sort' ][ 0 ] = 'changed'
            expect( @sort.keys.first ).to eql( old_sort_key )

            old_sort_value = @sort.values.first
            result[ 'direction' ][ 0 ] = 'changed'
            expect( @sort.values.first ).to eql( old_sort_value )
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

          context 'overwrites only provided parameters' do
            it 'with single element sort/direction arrays' do
              test_replacements( {
                'offset'      => @offset,
                'limit'       => @limit,
                'sort'        => [ @sort.keys.first   ],
                'direction'   => [ @sort.values.first ],
                'search_data' => @search,
                'filter_data' => @filter
              } )
            end

            # The default Request object has only one 'sort_data' key-value
            # pair, so if we tried to replace "one half" of that with more
            # elements, we should get an exception about mismatched lengths.
            #
            context 'with multi-element sort/direction arrays' do
              it 'and raises an exception if changing sort only' do
                expect {
                  request = Hoodoo::Services::Request.new
                  request.list.from_h!( { 'sort' => @sort.keys } )
                }.to raise_error( RuntimeError, 'Hoodoo::Services::Request::ListParameters#from_h!: Sort and direction array lengths must match' )
              end

              it 'and raises an exception if changing direction only' do
                expect {
                  request = Hoodoo::Services::Request.new
                  request.list.from_h!( { 'direction' => @sort.keys } )
                }.to raise_error( RuntimeError, 'Hoodoo::Services::Request::ListParameters#from_h!: Sort and direction array lengths must match' )
              end

              it 'and works if changing sort and direction' do
                request = Hoodoo::Services::Request.new
                request.list.from_h!( { 'sort' => @sort.keys, 'direction' => @sort.values } )
                expect( request.list.sort_data ).to eql( @sort )
              end
            end
          end
        end
      end
    end

    # ========================================================================

    context '#from_h!' do
      context 'edge case' do
        context 'of mismatched sort and direction arrays' do
          it 'raises an exception' do
            expect {
              request = Hoodoo::Services::Request.new
              request.list.from_h!( { 'sort' => [ '1', '2' ], 'direction' => [ '1', '2', '3' ] } )
            }.to raise_error( RuntimeError, 'Hoodoo::Services::Request::ListParameters#from_h!: Sort and direction array lengths must match' )

            expect {
              request = Hoodoo::Services::Request.new
              request.list.from_h!( { 'sort' => [ '1', '2', '3' ], 'direction' => [ '1', '2' ] } )
            }.to raise_error( RuntimeError, 'Hoodoo::Services::Request::ListParameters#from_h!: Sort and direction array lengths must match' )
          end
        end

        context 'of nil sort keys and directions' do
          it 'works if the arrays still match' do
            request = Hoodoo::Services::Request.new
            request.list.from_h!( { 'sort' => [ '1', nil, '2' ], 'direction' => [ '1', '2', nil ] } )
            expect( request.list.sort_data ).to eql( { '1' => '1', '2' => '2' } )
          end

          it 'raises an exception if the arrays then mismatch' do
            expect {
              request = Hoodoo::Services::Request.new
              request.list.from_h!( { 'sort' => [ '1', '2', '3' ], 'direction' => [ '1', '2', nil ] } )
            }.to raise_error( RuntimeError, 'Hoodoo::Services::Request::ListParameters#from_h!: Sort and direction array lengths must match' )
          end
        end
      end
    end

  end # "context '#list' do"
end   # "describe Hoodoo::Services::Request do"
