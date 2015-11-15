require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Writer do

  context 'persist_in' do

    ###########################################################################
    # DATABASE AND MODEL SETUP
    ###########################################################################

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
      include Hoodoo::ActiveRecord::ErrorMapping
    end

    before( :all ) do
      spec_helper_silence_stdout() do
        ActiveRecord::Migration.create_table(:r_spec_model_writer_tests, :id => false) do | t |
          t.text :id
          t.text :uuid
          t.text :code
          t.text :random_field

          t.timestamps :null => false
        end

        ActiveRecord::Migration.add_index(:r_spec_model_writer_tests, :code, unique: true)
      end
    end

    ###########################################################################
    # TESTS
    ###########################################################################

    def unique_attributes
      {
        :id           => Hoodoo::UUID.generate(),
        :code         => Hoodoo::UUID.generate(),
        :random_field => Hoodoo::UUID.generate()
      }
    end

    before( :each ) do
      @record_with_app_validation = RSpecModelWriterTestWithValidation.create(
        :id           => 'one',
        :code         => 'unique',
        :random_field => 'sudo random value'
      )

      @record_without_app_validation = RSpecModelWriterTestWithoutValidation.create(
        :id           => 'two',
        :code         => 'unique - but only far as the db is concerned',
        :random_field => 'sudo random value'
      )

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

    context 'saves valid records' do
      def expect_no_error( record )
        expect( record.persisted? ).to eq( true )
        @context.response.add_errors( record.platform_errors )
        expect( @context.response.halt_processing? ).to eq( false )
      end

      shared_examples 'a persist_in-able model' do | klass |
        it 'via class method' do
          expect(
            record = klass.persist_in( @context, unique_attributes() )
          ).to be_a( klass )

          expect_no_error( record )
        end

        it 'via instance method' do
          record = klass.new( unique_attributes() )
          result = record.persist_in( @context )
          expect( result ).to eq( :success )
          expect_no_error( record )
        end
      end

      context 'with AR validations present' do
        it_behaves_like 'a persist_in-able model', RSpecModelWriterTestWithValidation
      end

      context 'with AR validations missing' do
        it_behaves_like 'a persist_in-able model', RSpecModelWriterTestWithoutValidation
      end
    end

    context 'adds correct errors for invalid records' do
      def expect_correct_error( record, reference )
        expect( record.persisted? ).to eq( false )
        @context.response.add_errors( record.platform_errors )
        expect( @context.response.errors.errors[ 0 ] ).to eq(
          {
            'code'      => 'generic.invalid_duplication',
            'message'   => 'has already been taken',
            'reference' => reference
          }
        )
      end

      shared_examples 'an errant model' do | klass, error_reference |
        it 'via class method' do
          expect(
            record = klass.persist_in( @context, record_to_copy().attributes() )
          ).to be_a( klass )

          expect_correct_error( record, error_reference )
        end

        it 'via instance method' do
          record = klass.new( record_to_copy().attributes() )
          result = record.persist_in( @context )
          expect( result ).to eq( :failure )
          expect_correct_error( record, error_reference )
        end
      end

      context 'with AR validations present' do

        # Needed due to RSpec / scoping quirks; can't pass an instance variable
        # to a shared example as a parameter; ends up 'nil' inside the example.
        #
        let( :record_to_copy ) { @record_with_app_validation }

        it_behaves_like 'an errant model',
                        RSpecModelWriterTestWithValidation,
                        'code' # This being the name of a known duplication-violating field
      end

      context 'with AR validations missing' do
        let( :record_to_copy ) { @record_without_app_validation }
        it_behaves_like 'an errant model',
                        RSpecModelWriterTestWithoutValidation,
                        'model instance' # This being the default name for an unknown duplication-violation cause
      end
    end

    # This tries to check that, despite the nested transaction and rollback
    # behaviour inside #persist_in, deep internal exceptions still propagate
    # out correctly. It assumes database rollbacks happened OK (that's up to
    # AR and the DB driver) and just makes sure the exception gets out.
    #
    context 'when internal exceptions occur' do
      it 'reports them correctly' do
        record = RSpecModelWriterTestWithValidation.new( @record_with_app_validation.attributes() )

        # This is a method called deep inside ActiveRecord in its Transactions
        # mixin. It is private, so this test is fragile.

        expect( record ).to receive( :add_to_transaction ).and_raise( 'boo!' )
        expect { result = record.persist_in( @context ) }.to raise_error( RuntimeError, 'boo!' )
      end
    end

    # Prove that we handle the classic ActiveRecord validation of:
    #
    #    Thread 1              Thread 2
    #    Check for dup?        --
    #    No dupe               Check for dup?
    #    => Save record        No dupe
    #    OK                    => Save record
    #                          Fails
    #
    # Two handler threads are set up to run through this scenario and each
    # uses a Ruby Queue to talk to the other when it needs to pause and wait
    # for the other thread to advance, in order to ensure the articial race
    # condition is provoked every time without reliance on dubious 'sleep's.
    #
    context 'with race conditions' do
      shared_examples 'a robust model' do | use_transaction |
        it 'and handles duplicates correctly' do
          attrs    = unique_attributes()

          record_1 = RSpecModelWriterTestWithValidation.new( attrs )
          record_2 = RSpecModelWriterTestWithValidation.new( attrs )

          queue_1  = Queue.new
          queue_2  = Queue.new

          thread_1 = Thread.new do
            queue_1.pop() # Wait until thread 2 gets going

            expect( record_1 ).to receive( :perform_validations ).once do
              queue_2 << :go # Tell thread 2 to run validations
              queue_1.pop()  # Wait for thread 2 to run validations
              true # Indicate successful validation, let save happen
            end

            result = if use_transaction
              record_1.transaction do
                record_1.persist_in( @context )
              end
            else
              record_1.persist_in( @context )
            end

            expect( result ).to eq( :success )

            queue_2 << :go # Tell thread 2 to save
          end

          thread_2 = Thread.new do
            queue_1 << :go
            queue_2.pop() # Wait for thread 1 to run validations, then tell us to go

            expect( record_2 ).to receive( :perform_validations ).once do
              queue_1 << :go # Now tell thread 1 to save
              queue_2.pop() # Wait for thread 2 to do the same as the above
              true # Indicate successful validation, let save happen
            end

            # Since the validation above will succeed but then try to save and that
            # will fail, we expect the Writer module to re-query "valid?" and in the
            # end to return ":failure".

            expect( record_2 ).to receive( :valid? ).once.and_call_original

            result = if use_transaction
              record_2.transaction do
                record_2.persist_in( @context )
              end
            else
              record_2.persist_in( @context )
            end

            expect( result ).to eq( :failure )
          end

          thread_1.join()
          thread_2.join()
        end
      end

      context 'and no outer transaction' do
        it_behaves_like 'a robust model', false
      end

      context 'and an outer transaction' do
        it_behaves_like 'a robust model', true
      end
    end

  end

end
