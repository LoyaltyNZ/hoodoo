# ApiTools::Presenters::BasePresenter

## Purpose

A class intended as base functionality for presenter layers. It is concerned with validating and mapping inbound JSON data to an internal data structure, or rendering internal data structures for "presentation" as sent (transmitted) JSON. `BasePresenter` provides a rich DSL for JSON schema definition and validation.

## Usage

In the your presenter classes:

    require 'api_tools'

Then extend the base class:

    module YourService
      class SomePresenter < ApiTools::Presenters::BasePresenter
        schema do
          ...
        end

The class provides the following methods, plus a DSL for JSON schema definition.

| Method   | Description   |
|:---------|:--------------|
| `self.schema(&block)` | Define the JSON schema for validation, please see below. |
| `self.validate(data)` | Validate the given parsed JSON data (e.g. from [`ApiTools::JsonPayload`](json_payload.md)) and return validation/schema structure errors if any. |
| `self.parse(data)`    | Parse the supplied data Hash using the schema defined (or default) mappings and return a ruby Hash of the result. |
| `self.render(data)`   | Render supplied data Hash using the schema defined (or default) mappings and return a ruby Hash of the result. |
| `self.get_schema`     | Return the schema graph. |

The intent is to decouple incoming JSON strings from internal hashes representing the equivalent data; and this in turn is decoupled from any persistence layer you might implement (e.g. ActiveRecord models). The conceptual code flow when you _receive_ data is:

* `JSON.parse` an incoming JSON string, keeping keys as strings (don't symbolize keys).
* Use `validate` to see if that incoming JSON is valid, according to a `BasePresenter` subclass you write which defines the expected/permitted schema of that inbound data.
* Use `parse` if the data is valid, to produce a parsed Hash. This step is technically only significantly useful if you use the `:mapping` option (see below) to break the otherwise 1:1 relationship between inbound JSON fields and your internal expected Hash. Performance permitting, though, you should always take this step as it allows you to introduce schema-level mappings in future (e.g. because of data migrations, API variations etc.) without then having to remember to update all of your code to add in the parsing step.
* After parsing, you'll have a validated, mapped ruby Hash representation of the JSON string you originally received, with string keys throughout.

The conceptual code flow when you _generate_ data is:

* Create a Hash with strings as keys containing the data you want to return.
* There's no equivalent mapped-data-validation step for outbound data; we assume you generate valid results (through e.g. automated test coverage).
* Use `render` to, in essence, do the opposite of `parse` - map backwards from your internal mapped data to the client-facing result. Automated tests can (perhaps) compare pre-and-post-render Hash data (taking into account mappings) to test validity of your generated data.
* `JSON.generate` the string to send out from the rendered Hash.

It may often be the case that inbound data and outbound data represents the same data structures and can share the same schema definition. If however you have differing requirements in context, especially with different requirement constraints, then define different schema classes for the inbound vs outbound data. For example - you might define a schema for some resource instance that a client can create. To create it, the client provides a few fields. The resource itself gains lots of emergent properties when created - e.g. a "created at" date - and you may wish to specify that in a schema as a present and required property for rendering; thus, you'd need the simpler, fewer-fields schema to validate the incoming client data used for creating the resource, plus the more complex, more-fields schema to use to render the full created resource representation.

## Validation Errors

An array of validation errors will be returned from `validate`, with the following rules:

* If a field has the options `:required => true` and is absent in the data: `generic.required_field_missing` with a suitable message and the field path as the reference.
* If a field is not of the correct type:
  * **array**: `generic.invalid_array`
  * **date**: `generic.invalid_date`
  * **datetime**: `generic.invalid_datetime`
  * **decimal**: `generic.invalid_decimal`
  * **float**: `generic.invalid_float`
  * **integer**: `generic.invalid_integer`
  * **object**: `generic.invalid_object`
  * **string**: `generic.invalid_string`

`string` requires a `:length => <integer>` option, and validation will return `generic.max_length_exceeded` if the data exceeds the allowed length.

`date` and `datetime` are valid if they are [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) dates or datetimes respectively, e.g.

* date: `1978-12-24`
* datetime: `1978-12-24T13:24:11Z`, `2014-09-01T12:03:22+12:00`

Validation will check for impossible dates (allowing Feb 29 in leap years), and will accept all timezones including `Z` (Zulu, +00:00 / UTC) for datetimes.

## Parsing

The `parse` method maps input data into the defined schema structure. By default, mappings are direct and one-to-one, i.e. the parser will expect the same field names and structure as defined. You can override this behaviour with the `:mapping` option on the field, e.g:

    schema do
      string :first_name, :required => true, :length => 128
      string :family_name, :required => true, :length => 128, :mapping => [:surname]

      string :address_1, :length => 128, :mapping => [ :address, :address_1 ]
      string :address_2, :length => 128, :mapping => [ :address, :address_2 ]
      string :address_3, :length => 128, :mapping => [ :address, :address_3 ]
      string :suburb, :length => 128, :mapping => [ :address, :suburb ]
      string :city_town, :length => 128, :mapping => [ :address, :city ]
      string :region_state, :length => 128, :mapping => [ :address, :state ]
      string :postcode_zip, :length => 128, :mapping => [ :address, :zip_code ]
      string :country_code, :length => 3, :mapping => [ :address, :iso_country ]
    end

In the above example, `first_name` in the model maps directly to the `first_name` field in the input data. However, `family_name` maps to `surname` at the same level. The address fields exist at the root level in the model, but are mapped to a subobject `address` in the input data - in addition, `city_town` maps to `address.city`, `region_state` maps to `address.state`, `postcode_zip` maps to `address.zip_code`, and `country_code` maps to `address.iso_country`.

**Note**: The parse method will return a Hash with *only* fields that are:

* Defined in the schema
* Present in the data to be parsed

This is to support partial updates, e.g. Using `parse` with the schema above:

  data = {
    "one" => "hello",
    "address" => {
      "state" => "Idaho"
    }
  }

  parsed = PresenterClass.parse(data)

  parsed = {
    "region_state" => "Idaho"
  }

Here, neither the `one` field nor the rest of schema fields have been included, as either the schema does not define the field, or the parsed data does not contain schema defined fields.

## Rendering

The `render` method essentially performs the inverse of the `parse` method, using either default or defined mappings to render a ruby `Hash` from an input `Hash` using the schema.

  parsed = {
    "region_state" => "Idaho"
  }

  rendered = PresenterClass.render(data)

  rendered = {
    "first_name" => nil,
    "family_name" => nil,
    "address" {
      "address_1" => nil,
      "address_2" => nil,
      "address_3" => nil,
      "suburb" => nil,
      "city" => nil,
      "state" => "Idaho",
      "zip_code" => nil,
      "iso_country" => nil
    }
  }

**Note**: In the case of `render`, *all fields* will be rendered regardless of whether the appear in the input `Hash` or not.

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
              string :provider_code, :required => true, :length => 32, :mapping => [:reward_provider_code]
              string :supplier_code, :required => true, :length => 32, :mapping => [:reward_supplier_code]
              string :reward_code, :required => true, :length => 32, :mapping => [:reward_reward_code]
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
