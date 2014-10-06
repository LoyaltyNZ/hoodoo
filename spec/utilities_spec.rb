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

    it 'should handle outer arrays' do
      data = [
        {
          'one' => 1,
          'two' => {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          }
        },
        {
          'one' => 5,
          'two' => {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          }
        }
      ]

      expect(ApiTools::Utilities.symbolize(data)).to eq([
        {
          :one => 1,
          :two => {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        },
        {
          :one => 5,
          :two => {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        }
      ])
    end

    it 'should handle inner arrays' do

      data = {
        'one' => 1,
        'two' => [
          {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          },
          {
            'three' => :nine,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          },
        ]
      }

      expect(ApiTools::Utilities.symbolize(data)).to eq({
        :one => 1,
        :two => [
          {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          },
          {
            :three => :nine,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        ]
      })
    end
  end

  describe "#to_integer?" do
    it 'should return integer equivalents for valid values' do
      expect(ApiTools::Utilities.to_integer?(21)).to eq(21)
      expect(ApiTools::Utilities.to_integer?('21')).to eq(21)
      expect(ApiTools::Utilities.to_integer?(:'21')).to eq(21)
    end

    it 'should return nil for invalid values' do
      expect(ApiTools::Utilities.to_integer?(2.1)).to eq(nil)
      expect(ApiTools::Utilities.to_integer?('hello')).to eq(nil)
      expect(ApiTools::Utilities.to_integer?(Time.now)).to eq(nil)
    end
  end
end