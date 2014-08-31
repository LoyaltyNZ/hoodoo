# ApiTools::JsonPayload

## Purpose

A module intended as a sinatra extension, providing standard JSON parsing to the `@payload` instance variable in the API call.

## Usage

In the your sinatra API class:

    require 'api_tools'

Then include the module in a class that extends `Sinatra::Base`

    module YourService
      class API < Sinatra::Base

        include ApiTools::JsonPayload

The module provides the following methods in the API class, available in the sinatra DSL and custom methods:

| Method   | Description   |
|:---------|:--------------|
| `process_json_payload` | Process the request body as JSON, and place a `Hash` of the parsed structure in the `@payload` instance variable (:symbolize_names => true, all JSON keys are symbols). If the JSON parsing fails, `halt` the API call immediately returning `400 Bad Request` and rendering any previously added errors plus a 'generic.bad_json' error in the response body. |

## Dependencies

`ApiTools::JsonPayload` includes [`ApiTools::JsonErrors`](json_errors.md) and Ruby stdlib `json`.

## Example

    require 'api_tools'

    # ...

    module Fulfilment
      class API < Sinatra::Base

        include ApiTools::JsonPayload

        before do
          process_json_payload

          # ...
        end

    post "/service_resource" do

      return JSON.fast_generate({
        "request": @payload
      })

    end
