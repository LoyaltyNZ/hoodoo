# ApiTools::PlatformContext

## Purpose

A module intended as a sinatra extension, providing standard platform context to the API. The platform context is currently read from the following HTTP headers:

| Header   | Description   |
|:---------|:--------------|
| `X-Subscriber-ID` | The subscriber ID |
| `X-Programme-ID` | The programme ID. |

Full platform implementation will get the platform context from the `X-Session-ID` header and provide more information in the `@platform_context` variable.

## Usage

In the your sinatra API class:

    require 'api_tools'

Then include the module in a class that extends `Sinatra::Base`

    module YourService
      class API < Sinatra::Base

        include ApiTools::PlatformContext

The module provides the following methods in the API class, available in the sinatra DSL and custom methods:

| Method   | Description   |
|:---------|:--------------|
| `check_platform_context` | Get the platform context from the `X-Subscriber-ID` and `X-Programme-ID` HTTP headers into the `@platform_context` instance variable. If either or both headers are not supplied or empty, `halt` the API request with `400 Bad Request`, rendering the `platform.subscriber_id_required` and/or `platform.programme_id_required` errors in the standard format as required. |
| `platform_context_prefix` | Return a string of the format `<subscriber_id>:<programme_id>:` |

The current list of errors can be accessed with the instance variable `@errors`, an array of the standard structure:

    [
      { :code => "<error_code>", :message => "<error_message>", :reference => "<error_reference>" },
      ...
    ]

## Dependencies

`ApiTools::PlatformContext` includes [`ApiTools::JsonErrors`](json_errors.md).

## Example

    require 'api_tools'

    # ...

    module YourService
      class YourClass

        include ApiTools::PlatformContext

        before do
          
          check_platform_context

        end

        get '/help/:id' do

          id = platform_context_prefix + params[:id]

          return get_help_content_for(id)
        end
      end
    end
