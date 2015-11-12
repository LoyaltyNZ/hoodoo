require 'spec_helper'

describe Hoodoo::Data::Resources::QueueProcessingRequest do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(6)

    expect(schema.properties['message_reference']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['state']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['queued_at']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['info']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['platform_requests']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['payload_errors']).to be_a(Hoodoo::Presenters::Array)
  end
end
