require 'spec_helper'
require 'time'

describe Hoodoo::Logger::StreamWriter do
  before :all do
    @temp_path = spec_helper_tmpfile_path()
    @stream = File.open( @temp_path, 'ab' )
  end

  after :all do
    @stream.close             rescue nil
    File.unlink( @temp_path ) rescue nil
  end

  it 'writes to streams' do

    instance = described_class.new( @stream )

    time = Time.parse("2014-01-01 00:00:00 UTC")
    expect( Time ).to receive( :now ).at_least( 1 ).times.and_return( time )

    instance.report( :a, :b, :c, :d )
    expect( File.exist?( @temp_path ) ).to be( true )
    @stream.close

    logged = File.read( @temp_path )
    expect( logged ).to eq( "A [2014-01-01T00:00:00.000000Z] b - c: :d\n")

  end
end
