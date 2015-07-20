require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Dated do
  pending 'is tested' do

    # For RCov only

    class Test
      include Hoodoo::ActiveRecord::Dated
      def self.all; end
    end

    ignored = true
    Test.dated( ignored )
    Test.dated_at( ignored )

    raise "Replace with real test"
  end
end
