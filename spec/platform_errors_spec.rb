require 'spec_helper'

describe ApiTools::PlatformErrors do

  before do
    class TestClass
      include ApiTools::PlatformErrors

      attr_accessor :errors

      def env
        @test_env
      end
    end

    @test = TestClass.new
  end

  describe '#clear_errors' do
    it 'should set @errors to []' do

      @test.errors = 9123878123
      @test.clear_errors

      expect(@test.errors).to eq []
    end
  end

  describe '#add_error' do
    it 'should initialise @errors if not set' do
      @test.errors = nil
      @test.add_error(1,2)

      expect(@test.errors).not_to be nil
    end

    it 'should add an error with correct structure' do
      @test.add_error(1,2)

      expect(@test.errors).to eq([{ :code =>1, :message =>2}])
    end

    it 'should add an error with a reference if specified' do
      @test.add_error(1,2,3)

      expect(@test.errors).to eq([{ :code =>1, :message =>2 ,:reference =>3}])
    end

    it 'should add multiple errors' do
      @test.add_error(1,2,3)
      @test.add_error(4,5,6)

      expect(@test.errors).to eq([
        { :code =>1, :message =>2 ,:reference =>3},
        { :code =>4, :message =>5 ,:reference =>6}
      ])
    end
  end

  describe '#has_errors?' do
    it 'should return false if errors are empty' do
      @test.clear_errors
      expect(@test.has_errors?).to eq(false)
    end

    it 'should return true if errors are notempty' do
      @test.add_error(4,5,6)
      expect(@test.has_errors?).to eq(true)
    end
  end

end