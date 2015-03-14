require 'spec_helper'

# Much of this class gets nontrivial coverage from middleware tests, which
# existed before the refactor of code from there, into endpoints.
#
# This file just picks up the loose ends.

describe Hoodoo::Client::Endpoint do
  it 'complains about unknown discovery results' do
    mock_discoverer = OpenStruct.new
    expect( mock_discoverer ).to receive( :discover ).once.and_return( OpenStruct.new )

    expect {
      described_class.endpoint_for( :Anything, 1, { :discoverer => mock_discoverer } )
    }.to raise_error( RuntimeError, "Hoodoo::Client::Endpoint::endpoint_for: Unrecognised discoverer result class of 'OpenStruct'" )
  end

  context 'with subclass mandatory methods' do

    # Create a subclas that must at least implement configure_with, else
    # instantiation would fail as the constructor calls this.
    #
    class RSpecBadEndpointSubclass < described_class
      def configure_with( a, b, c )
      end
    end

    before :each do
      @endpoint = RSpecBadEndpointSubclass.new(
        :Anything,
        1,
        {}
      )
    end

    it 'complains about missing #configure_with' do
      # Trying to instantiate Endpoint directly leads it to call its own
      # implementation of #configure_with, which should raise an exception.

      expect {
        described_class.new(
          :Anything,
          1,
          {}
        )
      }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#configure_with' )
    end

    it 'complains about missing #list' do
      expect { @endpoint.list }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#list' )
    end

    it 'complains about missing #show' do
      expect { @endpoint.show( 'foo' ) }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#show' )
    end

    it 'complains about missing #create' do
      expect { @endpoint.create( {} ) }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#create' )
    end

    it 'complains about missing #update' do
      expect { @endpoint.update( 'foo', {} ) }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#update' )
    end

    it 'complains about missing #delete' do
      expect { @endpoint.delete( 'foo' ) }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::Client::Endpoint#delete' )
    end

  end
end
