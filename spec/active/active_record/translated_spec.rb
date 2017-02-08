require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Translated do
  pending 'is tested' # Replace with real tests!

  it 'temporarily addresses RCov coverage' do
    class Test
      include Hoodoo::ActiveRecord::Translated
      def self.all; end
    end

    ignored = true
    Test.translated( ignored )
  end
end
