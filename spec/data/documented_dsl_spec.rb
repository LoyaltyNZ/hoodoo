require "spec_helper"

describe ApiTools::Data::DocumentedDSL do
  # There are few tests needed beyond the DocumentedPresenter tests at
  # present.

  describe '#type' do
    it 'should raise an error for unrecognised types' do
      expect {
        class ErroneousDocumentedDSLTest < ApiTools::Data::DocumentedPresenter
          schema do
            object :obj do
              type :DoesNotExist
            end
          end
        end
      }.to raise_error(RuntimeError, "DocumentedObject#type: Unrecognised type name 'DoesNotExist'")
    end
  end
end
