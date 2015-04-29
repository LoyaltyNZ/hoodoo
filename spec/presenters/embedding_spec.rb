require "spec_helper"

describe Hoodoo::Presenters::Embedding::Embeds do
  before :each do
    @instance = described_class.new
  end

  it '#resource_key' do
    expect( @instance.resource_key ).to eq( '_embed' )
  end

  it '#add_one' do
    member = { 'first_name' => 'Anna' }
    @instance.add_one( 'member', member )
    expect( @instance.retrieve ).to eq( { 'member' => member } )

    expect {
      @instance.add_one( 'foo', 'not a Hash' )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::Embeds#add_one requires a rendered resource Hash, but was given an instance of String' )
  end

  it '#add_many' do
    members = [ { 'first_name' => 'Anna' }, { 'first_name' => 'Bailey' } ]
    @instance.add_many( 'members', members )
    expect( @instance.retrieve ).to eq( { 'members' => members } )

    expect {
      @instance.add_many( 'foo', 'not an Array' )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::Embeds#add_many requires an Array, but was given an instance of String' )

    expect {
      @instance.add_many( 'foo', [ 'not a Hash' ] )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::Embeds#add_many requires an Array of rendered resource Hashes, but the first Array entry is an instance of String' )
  end

  it '#remove' do
    member = { 'first_name' => 'Anna' }
    voucher = { 'description' => '$5 off your next purchase' }
    @instance.add_one( 'member', member )
    @instance.add_one( 'voucher', voucher )
    @instance.remove( 'member' )
    expect( @instance.retrieve ).to eq( { 'voucher' => voucher } )
  end
end

describe Hoodoo::Presenters::Embedding::References do
  before :each do
    @instance = described_class.new
  end

  it '#resource_key' do
    expect( @instance.resource_key ).to eq( '_reference' )
  end

  it '#add_one' do
    member = Hoodoo::UUID.generate
    @instance.add_one( 'member', member )
    expect( @instance.retrieve ).to eq( { 'member' => member } )

    expect {
      @instance.add_one( 'foo', 'not a UUID' )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::References#add_one requires a valid UUID String, but the given value is invalid' )
  end

  it '#add_many' do
    members = [ Hoodoo::UUID.generate, Hoodoo::UUID.generate ]
    @instance.add_many( 'members', members )
    expect( @instance.retrieve ).to eq( { 'members' => members } )

    expect {
      @instance.add_many( 'foo', 'not an Array' )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::References#add_many requires an Array, but was given an instance of String' )

    expect {
      @instance.add_many( 'foo', [ 'not a UUID' ] )
    }.to raise_exception( RuntimeError, 'Hoodoo::Presenters::Embedding::References#add_many requires an Array of valid UUID strings, but the first Array entry is invalid' )
  end

  it '#remove' do
    member = Hoodoo::UUID.generate
    voucher = Hoodoo::UUID.generate
    @instance.add_one( 'member', member )
    @instance.add_one( 'voucher', voucher )
    @instance.remove( 'member' )
    expect( @instance.retrieve ).to eq( { 'voucher' => voucher } )
  end
end
