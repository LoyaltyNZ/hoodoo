require 'spec_helper'

describe Hoodoo::UUID do

  describe '#generate' do
    it 'should generate a 32 character string' do
      uuid = Hoodoo::UUID.generate

      expect(uuid).to be_a(String)
      expect(uuid.length).to eq(32)
    end

    it 'should not generate the same uuid twice' do
      uuid1 = Hoodoo::UUID.generate
      uuid2 = Hoodoo::UUID.generate

      expect(uuid1).not_to eq(uuid2)
    end
  end
end