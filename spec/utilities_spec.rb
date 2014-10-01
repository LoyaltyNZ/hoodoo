require 'spec_helper'

describe ApiTools::Utilities do

  describe '#symbolize' do
    it 'should symbolize keys on a nested hash' do
      data = {
        'one' => 1,
        'two' => {
          'three' => :three,
          'four' => {
            :five => 'five',
            'six' => '6'
          }
        }
      }

      data[0] = 'zero'

      expect(ApiTools::Utilities.symbolize(data)).to eq({
        :'0' => 'zero',
        :one => 1,
        :two => {
          :three => :three,
          :four => {
            :five => 'five',
            :six => '6'
          }
        }
      })
    end

    it 'should not generate the same uuid twice' do
      uuid1 = ApiTools::UUID.generate
      uuid2 = ApiTools::UUID.generate

      expect(uuid1).not_to eq(uuid2)
    end
  end
end