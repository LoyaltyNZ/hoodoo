require 'spec_helper.rb'

# This is little more than a coverage exercise.

describe Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics do
  context 'InstanceExtensions' do
    class NewRelicInstanceExtensionsTest
      include Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics::InstanceExtensions
    end

    it 'call NewRelic' do
      Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics::InstanceExtensions.monkey_log_inbound_request()
    end
  end
end
