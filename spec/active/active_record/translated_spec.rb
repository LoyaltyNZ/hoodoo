require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Translated do
  pending 'is tested' do

    # For RCov only

    class Test
      include Hoodoo::ActiveRecord::Translated
      def self.all; end
    end

    ignored = true
    Test.translated( ignored )

    raise "Replace with real test"
  end
end
