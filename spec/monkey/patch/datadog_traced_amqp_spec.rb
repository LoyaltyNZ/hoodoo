require 'spec_helper.rb'

# We need to run these tests in order. First a bunch of shared examples
# run. Then we check to see if hook methods were invoked in passing. You
# can't do that in an 'after' hook as exceptions therein cause warnings
# to be printed, but don't cause test failures.
#
describe Hoodoo::Monkey::Patch::DatadogTracedAMQP, :order => :defined do

  # Not every test in the 'an AMQP-based middleware/client endpoint' shared
  # example group will provoke a request. We cannot expect to have the
  # NewRelic hooks called for every example. We *can* expect them to be
  # called several times though, so use 'allow' to track those calls and
  # count them.
  #
  before :all do
    @@endpoint_do_amqp_count  = 0
    @@datadog_trace_count     = 0

    # Stub Datadog
    class Datadog
      def self.tracer
        Datadog.new
      end
    end

    Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::DatadogTracedAMQP )
  end

  after :all do
    Hoodoo::Monkey.disable( extension_module: Hoodoo::Monkey::Patch::DatadogTracedAMQP )
    Object.send( :remove_const, :Datadog )
  end

  before :each do
    expect( Hoodoo::Client::Endpoint::AMQP.ancestors ).to include( Hoodoo::Monkey::Patch::DatadogTracedAMQP::InstanceExtensions )

    original_do_amqp = Hoodoo::Client::Endpoint::AMQP.instance_method( :do_amqp )

    allow_any_instance_of( Hoodoo::Client::Endpoint::AMQP ).to receive( :do_amqp ) do | instance, description_of_request |
      result = original_do_amqp.bind( instance ).call( description_of_request )
      @@endpoint_do_amqp_count += 1
      result
    end

    allow_any_instance_of( Datadog ).to receive( :trace ) do | &block |
      # Datadog Trace method responds with a yielded span this is here to mock tha
      span = double('span', trace_id: 'trace_id', span_id: 'span_id').as_null_object
      @@datadog_trace_count += 1
      block.call(span)
    end
  end

  it_behaves_like(
    'an AMQP-based middleware/client endpoint',
    {
      'X_DATADOG_TRACE_ID'        => 'trace_id',
      'X_DATADOG_PARENT_ID'       => 'span_id',

      'X_DDTRACE_PARENT_TRACE_ID' => 'trace_id',
      'X_DDTRACE_PARENT_SPAN_ID'  => 'span_id',
    }
  )

  context 'afterwards' do
    it 'has non-zero NewRelic method call counts' do
      expect( @@endpoint_do_amqp_count ).to be > 5
      expect( @@datadog_trace_count ).to eq( @@endpoint_do_amqp_count )
    end
  end
end