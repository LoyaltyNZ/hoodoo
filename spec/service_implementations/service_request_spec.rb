require 'spec_helper'

describe ApiTools::ServiceRequest do
  context 'uri_path_components' do
    before do
      @r = ApiTools::ServiceRequest.new
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
      expect( @r.locale              ).to eq( 'en-nz'      )
      expect( @r.body                ).to eq( nil          )
      expect( @r.uri_path_components ).to eq( []           )
      expect( @r.ident               ).to eq( nil          )
      expect( @r.uri_path_extension  ).to eq( ''           )
      expect( @r.list_offset         ).to eq( 0            )
      expect( @r.list_limit          ).to eq( 50           )
      expect( @r.list_sort_key       ).to eq( 'created_at' )
      expect( @r.list_sort_direction ).to eq( 'desc'       )
      expect( @r.list_search_data    ).to eq( {}           )
      expect( @r.list_filter_data    ).to eq( {}           )
      expect( @r.embeds              ).to eq( []           )
      expect( @r.references          ).to eq( []           )
    end
  end
end
