require "spec_helper"

describe ApiTools::Presenters::BaseDSL do

  # There are few tests needed beyond the base presenter tests at
  # present.

  describe '#type' do
    it 'should raise an error for unrecognised types' do
      expect {
        class ErroneousDocumentedDSLTest < ApiTools::Presenters::Base
          schema do
            object :obj do
              type :DoesNotExist
            end
          end
        end
      }.to raise_error(RuntimeError, "DocumentedObject#type: Unrecognised type name 'DoesNotExist'")
    end
  end

  describe '#resource' do
    class ApiTools::Data::Resources::TestResource < ApiTools::Presenters::Base
      schema do
        internationalised

        text :name
      end
    end

    it 'should raise an error for unrecognised resources' do
      expect {
        class ErroneousDocumentedDSLTest < ApiTools::Presenters::Base
          schema do
            resource :DoesNotExist
          end
        end
      }.to raise_error(RuntimeError, "DocumentedObject#resource: Unrecognised resource name 'DoesNotExist'")
    end

    it 'should not raise an error for existing resources' do
      expect {
        class DocumentedDSLTest < ApiTools::Presenters::Base
          schema do
            resource :TestResource
          end
        end
      }.not_to raise_error
    end
  end
end
