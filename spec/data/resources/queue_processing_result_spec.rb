require 'spec_helper'

describe Hoodoo::Data::Resources::QueueProcessingResult do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['status']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['queue_processing_request_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['queue_processing_request_id'].resource).to eq(:QueueProcessingRequest)
    expect(schema.properties['platform_results']).to be_a(Hoodoo::Presenters::Array)
  end
end
