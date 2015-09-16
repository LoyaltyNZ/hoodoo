require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Writer do
  before :all do

    ###########################################################################
    #                         DATABASE AND MODEL SETUP
    ###########################################################################

    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table(:r_spec_model_writer_tests, :id => false) do | t |
        t.text :id
        t.text :uuid
        t.text :code
        t.text :random_field

        t.timestamps
      end

      ActiveRecord::Migration.add_index(:r_spec_model_writer_tests, :code, unique: true)
    end

    class RSpecModelWriterTestWithValidation < ActiveRecord::Base
      self.primary_key = :id
      self.table_name = :r_spec_model_writer_tests

      include Hoodoo::ActiveRecord::Writer
      include Hoodoo::ActiveRecord::ErrorMapping

      validates :code, uniqueness: true
    end

    class RSpecModelWriterTestWithoutValidation < ActiveRecord::Base
      self.primary_key = :id
      self.table_name = :r_spec_model_writer_tests

      include Hoodoo::ActiveRecord::Writer
    end
  end

  ###########################################################################
  #                                 TESTS
  ###########################################################################

  context 'persist_in' do

    before(:each) do
      @record_with_app_validation = RSpecModelWriterTestWithValidation.create(
        id: 'one',
        code: 'unique',
        random_field: 'sudo random value'
      )

      @record_without_app_validation = RSpecModelWriterTestWithoutValidation.create(
        id: 'two',
        code: 'unique - but only far as the db is concerned',
        random_field: 'sudo random value'
      )
    end

    before(:each) do
      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    context 'adds an invalid duplicate error where AR validations are missing' do
      def expect_correct_error
        expect(@context.response.errors.errors).to eq(
          [{"code"=>"generic.invalid_duplication",
            "message"=>"Cannot create this resource instance due to a uniqueness constraint violation",
            "reference"=>"unknown"}]
        )
      end

      it 'via class method' do
        expect(
          RSpecModelWriterTestWithoutValidation.persist_in(@context, @record_without_app_validation.attributes)
        ).to be_a(RSpecModelWriterTestWithoutValidation)
      end

      it 'via instance method' do
        record = RSpecModelWriterTestWithoutValidation.new(@record_without_app_validation.attributes)

        expect(
          record.persist_in(@context)
        ).to be_a(RSpecModelWriterTestWithoutValidation)
      end
    end

    context 'adds an invalid duplicate error where AR validations are present' do
      def expect_correct_error
        expect(@context.response.errors.errors).to eq(
          [{"code"=>"generic.invalid_duplication",
            "message"=>"has already been taken",
            "reference"=>"code"}]
        )
      end

      it 'via class method' do
        expect(
          RSpecModelWriterTestWithValidation.persist_in(@context, @record_with_app_validation.attributes)
        ).to be_a(RSpecModelWriterTestWithValidation)
      end

      it 'via instance method' do
        record = RSpecModelWriterTestWithValidation.new(@record_with_app_validation.attributes)

        expect(
          record.persist_in(@context)
        ).to be_a(RSpecModelWriterTestWithValidation)
      end
    end
  end

end
