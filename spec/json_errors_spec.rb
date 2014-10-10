require 'spec_helper'
require "api_tools/json_errors"

describe ApiTools::JsonErrors do

  before do
    class TestClass
      include ApiTools::JsonErrors

      attr_accessor :errors

      def env
        @test_env
      end
    end

    @test = TestClass.new
  end

  describe '#fail_with_error' do
    it 'should call add_error and fail_with_errors correctly' do
      expect(@test).to receive(:add_error).with(2,3,4)
      expect(@test).to receive(:fail_with_errors).with(422)

      @test.fail_with_error(422,2,3,4)
    end

    it 'should respect existing errors' do
      @test.add_error(1,2,3)

      expect(@test).to receive(:fail_with_errors).with(422)

      @test.fail_with_error(422,2,3,4)

      expect(@test.errors).to eq([
        { 'code' =>1, 'message' =>2 ,'reference' =>3},
        { 'code' =>2, 'message' =>3 ,'reference' =>4}
      ])
    end
  end

  describe '#fail_with_errors' do
    it 'should call halt with correct status and JSON' do
      @test.errors = { :one =>1, :two =>2 }

      expect(@test).to receive(:halt).with(504, '{"errors":{"one":1,"two":2}}')

      @test.fail_with_errors(504)
    end

    it 'should call halt with default 422 status and JSON' do
      @test.errors = { :one =>1, :two =>2 }

      expect(@test).to receive(:halt).with(422, '{"errors":{"one":1,"two":2}}')

      @test.fail_with_errors
    end

    it 'should add more errors if specified' do
      @test.errors = [{ :one =>1, :two =>2 }]

      expect(@test).to receive(:halt).with(422, "{\"errors\":[{\"one\":1,\"two\":2},{\"five\":5,\"six\":6}]}")

      @test.fail_with_errors 422, [{:five=>5,:six=>6}]
    end
  end

  describe '#fail_not_found' do
    it 'should call fail_not_found with 404 and message' do
      expect(@test).to receive(:fail_with_errors).with(404)
      @test.fail_not_found
    end
  end

  describe '#fail_unauthorized' do
    it 'should call fail_not_found with 404 and message' do
      expect(@test).to receive(:fail_with_error).with(401, 'platform.unauthorized','Authorization is required to perform this operation on the resource.')
      @test.fail_unauthorized
    end
  end

  describe '#fail_forbidden' do
    it 'should call fail_not_found with 404 and message' do
      expect(@test).to receive(:fail_with_error).with(403, 'platform.forbidden','The user is not allowed to perform this operation on the resource.')
      @test.fail_forbidden
    end
  end
end
