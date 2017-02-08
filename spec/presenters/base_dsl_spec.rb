require "spec_helper"

describe Hoodoo::Presenters::BaseDSL do

  # There are few tests needed beyond the base presenter tests at
  # present.

  describe '#type' do
    class Hoodoo::Data::Types::TestType < Hoodoo::Presenters::Base
      schema do
        text :name
      end
    end

    class ArbitraryTestType < Hoodoo::Presenters::Base
      schema do
        float :floaty
      end
    end

    it 'should raise an error for unrecognised types' do
      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            object :obj do
              type :DoesNotExist
            end
          end
        end
      }.to raise_error(RuntimeError, "Hoodoo::Presenters::Base#type: Unrecognised type name 'DoesNotExist'")
    end

    it 'should not raise an error for existing types' do
      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            type :TestType
          end
        end
      }.not_to raise_error

      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            type Hoodoo::Data::Types::TestType
          end
        end
      }.not_to raise_error

      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            type ArbitraryTestType
          end
        end
      }.not_to raise_error
    end
  end

  describe '#resource' do
    class Hoodoo::Data::Resources::TestResource < Hoodoo::Presenters::Base
      schema do
        internationalised

        text :name
      end
    end

    class ArbitraryTestResource < Hoodoo::Presenters::Base
      schema do
        float :floaty
      end
    end

    it 'should raise an error for unrecognised resources' do
      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            resource :DoesNotExist
          end
        end
      }.to raise_error(RuntimeError, "Hoodoo::Presenters::Base#resource: Unrecognised resource name 'DoesNotExist'")
    end

    it 'should not raise an error for existing resources' do
      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            resource :TestResource
          end
        end
      }.not_to raise_error

      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            resource Hoodoo::Data::Resources::TestResource
          end
        end
      }.not_to raise_error

      expect {
        class BaseDSLTest < Hoodoo::Presenters::Base
          schema do
            resource ArbitraryTestResource
          end
        end
      }.not_to raise_error
    end
  end

  describe '#type_option_to_class' do
    it 'should raise an error for unrecognised types' do
      expect {
        klass = Hoodoo::Presenters::Object.new
        klass.send( :type_option_to_class, :foo )
      }.to raise_error(RuntimeError, "Unsupported 'type' option value of 'foo' in Hoodoo::Presenters::BaseDSL")
    end
  end

  describe '#extract_field_prefix_options_from' do
    it 'should extract options' do
      data = {
        :default => :foo,
        :field_one => :one,
        'field_two' => :two,
        'field_three-three three' => { :three => 3 }
      }

      klass  = Hoodoo::Presenters::Object.new
      result = klass.send( :extract_field_prefix_options_from, data )

      expect( result ).to( eql( {
        :one => :one,
        :two => :two,
        :'three-three three' => { :three => 3 }
      } ) )
    end
  end
end
