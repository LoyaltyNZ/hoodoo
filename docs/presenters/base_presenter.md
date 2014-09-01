# ApiTools::Presenters::BasePresenter

## Purpose

A class intended as base functionality for presenter layers in sinatra services. Although Parsing and rendering of JSON is left to the extender, `BasePresenter` provides a rich DSL for JSON schema definition and validation.

## Usage

In the your presenter classes:

    require 'api_tools'

Then extend the base class:

    module YourService
      class SomePresenter < ApiTools::Presenters::BasePresenter

      ...

The class provides the following methods, plus a DSL for JSON schema definition.

| Method   | Description   |
|:---------|:--------------|
| `self.schema(&block)` | Define the JSON schema for validation, please see below. |
| `self.validate(data)` | Validate the given parsed JSON data (e.g. from [`ApiTools::JsonPayload`](json_payload.md)) and return validation/schema structure errors if any. |
| `self.get_schema`     | Return the schema graph. |

## Validation Errors

An array of validation errors will be returned from `validate`, with the following rules:

* If a field has the options `:required => true` and is absent in the data: `generic.required_field_missing` with a suitable message and the field path as the reference.
* If a field is not of the correct type:
** **array**: `generic.invalid_array`
** **date**: `generic.invalid_date`
** **datetime**: `generic.invalid_datetime`
** **decimal**: `generic.invalid_decimal`
** **float**: `generic.invalid_float`
** **integer**: `generic.invalid_integer`
** **object**: `generic.invalid_object`
** **string**: `generic.invalid_string`

`string` requires a `:length => <integer>` option, and validation will return `generic.max_length_exceeded` if the data exceeds the allowed length.

`date` and `datetime` are valid if they are [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) dates or datetimes respectively, e.g.

* date: `1978-12-24`
* datetime: `1978-12-24T13:24:11Z`, `2014-09-01T12:03:22+12:00`

Validation will check for impossible dates (allowing Feb 29 in leap years), and will accept all timezones including `Z` (Zulu, +00:00 / UTC) for datetimes.

## Dependencies

`ApiTools::Presenters::BasePresenter` requires the contents of the **types** directory, loading the following:

| Name              | Description                                  |
|:------------------|:---------------------------------------------|
| types/field.rb    | The base class for field schema definitions. |
| types/array.rb    | The `array` DSL command.                     |
| types/boolean.rb  | The `boolean` DSL command.                   |
| types/date.rb     | The `date` DSL command.                      |
| types/datetime.rb | The `datetime` DSL command.                  |
| types/decimal.rb  | The `decimal` DSL command.                   |
| types/float.rb    | The `float` DSL command.                     |
| types/integer.rb  | The `integer` DSL command.                   |
| types/object.rb   | The `object` DSL command.                    |
| types/string.rb   | The `string` DSL command.                    |

## Example & Schema DSL

    require "api_tools"
    require 'json_builder'

    module Fulfilment
      module Presenters
        class FulfilmentPresenter < ApiTools::Presenters::BasePresenter

          attr_accessor :errors

          schema do
            integer :quantity, :required => true 
            string :client_id, :required => true, :length => 32 
            string :status_callback_uri, :required => false, :length => 256 
            object :reward, :required => true do
              string :provider_code, :required => true, :length => 32 
              string :supplier_code, :required => true, :length => 32 
              string :reward_code, :required => true, :length => 32 
            end
            object :member, :required => true do
              string :id, :required => true, :length => 32 
              string :first_name, :required => true, :length => 128 
              string :family_name, :required => true, :length => 128 
              date :dob, :required => true
              string :email, :required => true, :length => 128 
            end
            object :delivery_target, :required => true do
              string :delivery_type, :required => true, :length => 32
              string :address_1, :length => 128
              string :address_2, :length => 128
              string :address_3, :length => 128
              string :suburb, :length => 128
              string :city_town, :length => 128
              string :region_state, :length => 128
              string :postcode_zip, :length => 128
              string :country_code, :length => 3
            end
          end

        end
      end
