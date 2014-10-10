# ApiTools::PlatformErrors

## Purpose

A module intended as a generic error handler for an instance of a class. Provides multiple error capability for a class in the standard platform error format: 

    @errors = [
      { 'code' => "<error_code>", 'message' => "<error_message>", 'reference' => "<error_reference>" },
      ...
    ]

## Usage

In the your sinatra API class:

    require 'api_tools'

Then include the module in a class that extends `Sinatra::Base`

    module YourService
      class YourClass

        include ApiTools::PlatformErrors

The module provides the following methods in the API class, available in the sinatra DSL and custom methods:

| Method   | Description   |
|:---------|:--------------|
| `clear_errors` | Clear all errors. |
| `add_error(code, message, reference = nil)` | Add an error with the specified `code`, `message`, and optionally `reference` to the error list. |
| `has_errors?` | Return `true` if errors have been added. |

The current list of errors can be accessed with the instance variable `@errors`, an array of the standard structure:

    [
      { 'code' => "<error_code>", 'message' => "<error_message>", 'reference' => "<error_reference>" },
      ...
    ]

## Dependencies

None.

## Example

    require 'api_tools'

    # ...

    module YourService
      class YourClass

        include ApiTools::PlatformErrors

        def some_method

          ...

          # Error
          if something_went_wrong
            add_error('yourservice.yourerror','The yourerror error has occured!!','some.reference.to.a.thing')
          end

          # Second Chance/Retry etc.
          if try_again
            clear_errors
          end

          # Do we have errors?
          return @errors if has_errors?
        end
      end
    end
