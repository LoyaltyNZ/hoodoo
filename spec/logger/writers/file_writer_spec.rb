require 'spec_helper'
require 'tempfile'

describe Hoodoo::Logger::FileWriter do

  before :all do
    @temp_path = spec_helper_tmpfile_path()
  end

  after :all do
    File.unlink( @temp_path ) rescue nil
  end

  it 'writes to files' do

    # Create the instance; should not write anything.
    #
    instance = described_class.new( @temp_path )
    expect( File.exist?( @temp_path ) ).to be( false )

    # Log a message.
    #
    time = Time.parse("2014-01-01 00:00:00 UTC")
    expect( Time ).to receive( :now ).at_least( 1 ).times.and_return( time )

    instance.report( :a, :b, :c, :d )
    expect( File.exist?( @temp_path ) ).to be( true )

    logged = File.read( @temp_path )
    expect( logged ).to eq( "A [2014-01-01T00:00:00.000000Z] b - c: :d\n")

  end
end
