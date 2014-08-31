# ApiTools::JsonErrors

## Purpose

A module intended as a sinatra extension, providing standard error functionality for Platform APIs. Methods are provided to add multiple error conditions, halt the API, and render the standard platform JSON error structure:

    {
      "errors": [
        { "code": "<error_code>", "message": "<error_message>", "reference": "<error_reference>"},
        ...
      ]
    }

## Usage

In the your sinatra API class:

    require 'api_tools'

Then include the module in a class that extends `Sinatra::Base`

    module YourService
      class API < Sinatra::Base

        include ApiTools::JsonErrors

The module provides the following methods in the API class, available in the sinatra DSL and custom methods:

| Method   | Description   |
|:---------|:--------------|
| `fail_with_error(status, code, message, reference = nil)` | `halt` the API call immediately, returning the supplied HTTP `status` code, and render any previously added errors plus an error with the supplied `code`, `message`, and optionally `reference`, in the response body. |
| `fail_with_error(status = 422, errors = nil)` | `halt` the API call immediately, returning the supplied HTTP `status` code, with any previously added errors plus all supplied `errors` in the response body. Please note `errors` should be an array of hashes conforming to the standard error interface. |
| `fail_not_found` | `halt` the API call immediately, returning `404 Not Found` and rendering any previously added errors in the response body. |
| `fail_unauthorized` | `halt` the API call immediately, returning `401 Unauthorized` and rendering any previously added errors plus a `platform.unauthorized` error in the response body. |
| `fail_forbidden` | `halt` the API call immediately, returning `403 Forbidden` and rendering any previously added errors plus a 'platform.forbidden' error in the response body. |

## Dependencies

`ApiTools::JsonErrors` includes [`ApiTools::PlatformErrors`](platform_errors.md).

## Example

    require 'api_tools'

    # ...

    module Fulfilment
      class API < Sinatra::Base

        include ApiTools::JsonErrors

        before do
          clear_errors

          # ...
        end

    post "/service_resource" do

      # ...

      # Check Client Id
      if settings.models[:fulfilment].client_id_exists?(
          @platform_context[:subscriber_id],
          @platform_context[:programme_id],
          @payload[:client_id],
        )
        fail_with_error 409, "fulfilment.client_id_exists", "A fulfilment with client_id `#{@payload[:client_id]}` already exists for this subscriber and programme",'client_id'
      end

    end
