shared_context 'error mapping' do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_error_mapping_tests ) do | t |
        t.string   :uuid
        t.boolean  :boolean
        t.date     :date
        t.datetime :datetime
        t.decimal  :decimal, :precision => 5, :scale => 2
        t.float    :float
        t.integer  :integer
        t.string   :string, :limit => 16
        t.text     :text
        t.time     :time
        t.text     :array, :array => true
      end unless ActiveRecord::Base.connection.table_exists?( :r_spec_model_error_mapping_tests )

      ActiveRecord::Migration.create_table( :r_spec_model_associated_error_mapping_tests ) do | t |
        t.string :other_string

        # For 'has_many' - can't use "t.reference" as the generated
        # column name is too long!
        #
        t.integer :many_id
        t.index   :many_id
      end unless ActiveRecord::Base.connection.table_exists?( :r_spec_model_associated_error_mapping_tests )

      class RSpecModelErrorMappingTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::ErrorMapping

        has_many :r_spec_model_associated_error_mapping_tests,
                 :foreign_key => :many_id,
                 :class_name  => :RSpecModelAssociatedErrorMappingTest

        accepts_nested_attributes_for :r_spec_model_associated_error_mapping_tests

        validates_presence_of :boolean,
                              :date,
                              :datetime,
                              :decimal,
                              :float,
                              :integer,
                              :string,
                              :text,
                              :time,
                              :array

        validates_uniqueness_of :integer
        validates :string, :length => { :maximum => 16 }
        validates :uuid, :uuid => true

        validate do
          if string == 'magic'
            errors.add( 'this.thing', 'is not a column' )
          end
        end
      end

      class RSpecModelAssociatedErrorMappingTest < ActiveRecord::Base
        belongs_to :r_spec_model_error_mapping_test,
                   :foreign_key => :many_id,
                   :class_name  => :RSpecModelErrorMappingTest

        validates :other_string, :length => { :maximum => 6 }
      end

      class RSpecModelErrorMappingTestBase < ActiveRecord::Base
        self.table_name = RSpecModelErrorMappingTest.table_name

        include Hoodoo::ActiveRecord::ErrorMapping

        validate do | instance |
          instance.errors.clear()
          instance.errors.add( :base, 'this is a test' )
        end
      end
    end
  end

  let( :valid_model ) {
    RSpecModelErrorMappingTest.new( {
      :uuid     => Hoodoo::UUID.generate(),
      :boolean  => true,
      :date     => Time.now,
      :datetime => Time.now,
      :decimal  => 2.3,
      :float    => 2.3,
      :integer  => 42,
      :string   => "hello",
      :text     => "hello",
      :time     => Time.now,
      :array    => [ 'hello' ]
    } )
  }
end
