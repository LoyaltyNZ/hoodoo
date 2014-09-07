require 'spec_helper'

describe ApiTools::ThreadSafeHash do

  describe '#initialize' do
    it 'should set hash and mutex properly' do
      instance = ApiTools::ThreadSafeHash.new

      expect(instance.hash).to be_a(Hash)
      expect(instance.mutex).to be_a(Mutex)
    end
  end

  describe '#[]' do
    it 'should call synchronize on mutex with [] on hash' do
      instance = ApiTools::ThreadSafeHash.new
      instance.mutex = double

      instance.hash[1] = true

      expect(instance.mutex).to receive(:synchronize) { |&block| block.call }
      expect(instance[1]).to eq(true)
    end
  end

  describe '#[]=' do
    it 'should call synchronize on mutex with [] on hash' do
      instance = ApiTools::ThreadSafeHash.new
      instance.mutex = double

      instance.hash[1] = true

      expect(instance.mutex).to receive(:synchronize) { |&block| block.call }
      
      instance[1]=false
      
      expect(instance.hash[1]).to eq(false)
    end
  end

  describe '#has_key?' do
    it 'should call synchronize on mutex with has_key? on hash' do
      instance = ApiTools::ThreadSafeHash.new
      instance.mutex = double

      expect(instance.hash).to receive(:has_key?).with(2).and_return(false)

      expect(instance.mutex).to receive(:synchronize) { |&block| block.call }
      
      expect(instance.has_key?(2)).to eq(false)
    end
  end

  describe '#delete' do
    it 'should call synchronize on mutex with delete on hash' do
      instance = ApiTools::ThreadSafeHash.new
      instance.mutex = double

      expect(instance.hash).to receive(:delete).with(3).and_return(true)

      expect(instance.mutex).to receive(:synchronize) { |&block| block.call }
      
      expect(instance.delete(3)).to eq(true)
    end
  end
end