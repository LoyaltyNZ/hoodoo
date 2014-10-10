require 'spec_helper'
require 'ostruct'

describe ApiTools::PlatformContext do

  before do
    class TestHaltException < Exception
      attr_reader 'code', 'message'

      def initialize(code, message)
        @code = code
        @message = message
      end
    end

    class TestClass
      attr_accessor :request, :payload, :env, :platform_context

      include ApiTools::PlatformContext

      def initialize(env={})
        @env = env
      end

      def halt(code, message)
        raise TestHaltException.new(code, message)
      end

      def request
        OpenStruct.new({
          :env => @env
        })
      end
    end

  end

  describe '#check_platform_context' do

    it 'should set subscriber and programme from headers' do

      @test = TestClass.new({
        "HTTP_X_SUBSCRIBER_ID" => "12345",
        "HTTP_X_PROGRAMME_ID" => "67890",
      })

      @test.check_platform_context

      expect(@test.platform_context[:subscriber_id]).to eq("12345")
      expect(@test.platform_context[:programme_id]).to eq("67890")
    end

    it 'should error when subscriber not set' do

      @test = TestClass.new({
        "HTTP_X_PROGRAMME_ID" => "67890",
      })

      expect {
        @test.check_platform_context
      }.to raise_error(TestHaltException) do |e|
        expect(e.code).to eq(400)
      end

      expect(@test.errors).to eq([{
        'code'=>"platform.subscriber_id_required",
        'message'=>"Please supply a `X-Subscriber-Id` HTTP header"
      }])

    end

    it 'should error when programme not set' do

      @test = TestClass.new({
        "HTTP_X_SUBSCRIBER_ID" => "12345",
      })

      expect {
        @test.check_platform_context
      }.to raise_error(TestHaltException) do |e|
        expect(e.code).to eq(400)
      end

      expect(@test.errors).to eq([
        {
          'code'=>"platform.programme_id_required",
          'message'=>"Please supply a `X-Programme-Id` HTTP header"
        }
      ])

    end
  end

  describe '#platform_context_prefix' do

    it 'should return the platform context prefix string' do
      @test = TestClass.new({
        "HTTP_X_SUBSCRIBER_ID" => "12345",
        "HTTP_X_PROGRAMME_ID" => "67890",
      })

      @test.check_platform_context

      expect(@test.platform_context_prefix).to eq("12345:67890:")
    end
  end
end