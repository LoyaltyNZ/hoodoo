require 'spec_helper'
require "api_tools/json_payload"

describe ApiTools::JsonPayload do

  before do
    class TestClass
      attr_accessor :request, :payload

      include ApiTools::JsonPayload
    end
    @test = TestClass.new
  end

  describe '#process_json_payload' do
    it 'should call rewind on request.body' do

      @test.request = OpenStruct.new({
        :body => OpenStruct.new({
          :read => OpenStruct.new({:length => 0})
          })
      })
      expect(@test.request.body).to receive(:rewind)

      @test.process_json_payload
    end

    it 'should call read and return with set payload nil if body length is less than 2' do
      @test.request = OpenStruct.new({
        :body => OpenStruct.new
      })
      expect(@test.request.body).to receive(:rewind)
      expect(@test.request.body).to receive(:read).and_return('')

      @test.process_json_payload

      expect(@test.payload).to be_nil
    end

    it 'should parse the body json into @payload, not symbolizing names' do
      @test.request = OpenStruct.new({
        :body => OpenStruct.new
      })
      expect(@test.request.body).to receive(:rewind)
      expect(@test.request.body).to receive(:read).and_return('{"one":1,"two":2}')

      @test.process_json_payload

      expect(@test.payload).to eq({ 'one'=>1, 'two' =>2})
    end

    it 'should parse the body json into @payload, symbolizing names' do
      @test.request = OpenStruct.new({
        :body => OpenStruct.new
      })
      expect(@test.request.body).to receive(:rewind)
      expect(@test.request.body).to receive(:read).and_return('{"one":1,"two":2}')

      @test.process_json_payload( true )

      expect(@test.payload).to eq({ :one=>1, :two =>2})
    end

    it 'should set @payload nil and call fail_with_error is JSON parse fails' do
      @test.request = OpenStruct.new({
        :body => OpenStruct.new
      })
      expect(@test.request.body).to receive(:rewind)
      expect(@test.request.body).to receive(:read).and_return('fw4oihwafosaf8')

      expect(@test).to receive(:fail_with_error).with(400, 'generic.bad_json',  'The JSON payload cannot be parsed')

      @test.process_json_payload

      expect(@test.payload).to be_nil
    end
  end
end
