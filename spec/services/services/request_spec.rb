require 'spec_helper'

describe Hoodoo::Services::Request do
  context 'uri_path_components' do
    before do
      @r = Hoodoo::Services::Request.new
    end

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

    it 'has correct default values' do
      expect( @r.locale              ).to eq( 'en-nz'                    )
      expect( @r.body                ).to eq( nil                        )
      expect( @r.uri_path_components ).to eq( []                         )
      expect( @r.ident               ).to eq( nil                        )
      expect( @r.uri_path_extension  ).to eq( ''                         )
      expect( @r.list.offset         ).to eq( 0                          )
      expect( @r.list.limit          ).to eq( 50                         )
      expect( @r.list_sort_data      ).to eq( { 'created_at' => 'desc' } )
      expect( @r.list.search_data    ).to eq( {}                         )
      expect( @r.list.filter_data    ).to eq( {}                         )
      expect( @r.embeds              ).to eq( []                         )
      expect( @r.references          ).to eq( []                         )
    end

    it 'supports deprecated accessors' do
      expect( @r.list_offset         ).to eq( 0                          )
      expect( @r.list_limit          ).to eq( 50                         )
      expect( @r.list_sort_data      ).to eq( { 'created_at' => 'desc' } )
      expect( @r.list_search_data    ).to eq( {}                         )
      expect( @r.list_filter_data    ).to eq( {}                         )

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
