# ApiTools::Presenters::Base

## Purpose

A class intended as base functionality for presenter layers. It is concerned with validating inbound data against a schema, or rendering internal data structures for "presentation" with schema-defined defaults. `BasePresenter` provides a rich DSL for schema definition and validation.

## Usage

In the your presenter classes:

        require 'api_tools'

Then extend the base class:

        module YourService
          class SomePresenter < ApiTools::Presenters::Base
            schema do
              ...
            end
          end
        end

The class provides the following methods, plus a DSL for schema definition.

| Method                     | Description   |
|:---------------------------|:--------------|
| `self.schema(&block)`      | Define the schema for validation - please see below. |
| `self.validate(data, ...)` | Validate the given Hash of data against the schema and return validation/schema structure errors if any. |
| `self.render(data, ...)`   | Render supplied data Hash including the schema defaults (if any) and return a ruby Hash of the result. |
| `self.get_schema`          | Return the schema graph. |

The intent is to decouple incoming (e.g.) JSON strings / other format inbound data from internal hashes representing the equivalent data; and this in turn is decoupled from any persistence layer you might implement (e.g. ActiveRecord models). The conceptual code flow when you _receive_ data is:

* `JSON.parse` an incoming JSON string, keeping keys as strings (don't symbolize keys).
* Use `validate` to see if that incoming JSON is valid, according to a `BasePresenter` subclass you write which defines the expected/permitted schema of that inbound data.
* That's all. You'll have a validated ruby Hash representation of the JSON string you originally received, with string keys throughout. If you want to merge in any default values on top of the data you got, run the input data through #render and examine the result.

The conceptual code flow when you _generate_ data is:

* Create a Hash with strings as keys containing the data you want to return.
* Use `validate` if you want to be sure that your outbound data is valid, according to a `BasePresenter` subclass you write which defines the expected/permitted schema of that outbound data.
* Use `render` to merge in any default values with the data you generated.
* `JSON.generate` the string to send out from the rendered Hash.

It may often be the case that inbound data and outbound data represents the same data structures and can share the same schema definition. If however you have differing requirements in context, especially with different requirement constraints, then define different schema classes for the inbound vs outbound data. For example - you might define a schema for some resource instance that a client can create. To create it, the client provides a few fields. The resource itself gains lots of emergent properties when created - e.g. a "created at" date - and you may wish to specify that in a schema as a present and required property for rendering; thus, you'd need the simpler, fewer-fields schema to validate the incoming client data used for creating the resource, plus the more complex, more-fields schema to use to render the full created resource representation.

## Validation Errors

An array of validation errors will be returned from `validate`. This includes platform-defined errors such as `generic.required_field_missing` if option `:required => true` is set on a field but a value is not provided for it, along with the various `generic.invalid_...` errors for fields where the value is not of the expected type.

Field type `string` requires a `:length => <integer>` option, and validation will return `generic.max_length_exceeded` if the data exceeds the allowed length. Within hashes, the `key` part of the DSL defines specific named keys expected in the hash, while the `keys` part describes just the generic "shape"/schema of keys (if required) and, like `string`, lets you specify a `:length => <integer>` option if you require that keys in the hash do not exceed a certain length.

`date` and `datetime` are valid if they are [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) dates or datetimes respectively, e.g.

* date: `1978-12-24`
* datetime: `1978-12-24T13:24:11Z`, `2014-09-01T12:03:22+12:00`

Validation will check for impossible dates (allowing Feb 29 in leap years), and will accept all timezones including `Z` (Zulu, +00:00 / UTC) for datetimes.

## Rendering

The `render` method applies schema defaults to an inbound data set, which in the case of things like the `hash` field type may be quite complex. The result is a ruby `Hash` from an input `Hash` using the schema.

The rules are:

* If a field is omitted on input, then it only appears in the output if the schema defines a default for it.
* If a field leading to an `object` or `hash` value type is provided as an empty object (`{}`) then default fields/keys from the schema, if any, will be added into that empty object.
* Explicit `nil` means `nil`. If you provide a nil value on input for any field, then it'll be a nil value in the outbound representation. No defaults can override it or appear here. The only exception is attempting to render `nil` overall - this is basically meaningless, so treated as if you'd tried to render an empty Hash.
* Fields in the input data which are not described in the schema will be stripped out. This includes unrecognised hash keys for hashes which use the `key` DSL method to list one or more specific expected named keys.

        class PresenterClass < ApiTools::Presenters::Base
          schema do
            object :address do
              text :town
              text :state
              text :country, :default => 'NZ'
              text :example, :default => 'nil overrides this default'
            end
          end
        end

        data = {
          :address => {
            :state => 'Idaho',
            :example => nil
          }
        }

        rendered = PresenterClass.render(data)

        rendered = {
          :address => {
            :state => 'Idaho',
            :country => 'NZ',
            :example => nil
          }
        }

## Dependencies

`ApiTools::Presenters::Base` requires the contents of the **presenters/types** directory.

## Example & Schema DSL

    require "api_tools"
    require 'json_builder'

    module Fulfilment
      module Presenters
        class FulfilmentPresenter < ApiTools::Presenters::Base

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

            # Field "array_with_any_values" must have an Array value, with
            # any array contents permitted. If the input data has a nil
            # value for this field, then nil would be rendered and it would
            # validate. Add ':required => true' to prohibit this.
            #
            # Example valid input:
            # { 'array_with_values' => [ 'hello', 4, :world ] }

            array :array_with_any_values, :default => [ 1, 2, 3 ]

            # Field "objects_with_two_text_fields" must have an Array value,
            # where values are either nil or an object with two text fields
            # "field_one" and "field_two".
            #
            # Example valid input:
            # { 'array_with_values' => [ { 'field_one' => 'one' },
            #                            { 'field_two' => 'two' } ] }

            array :objects_with_two_text_fields do
              text :field_one
              text :field_two
            end

            # A field "any_allowed_hash" must have a Hash value, with any
            # hash contents permitted. 'default' could be used to provide
            # an entire default Hash value for rendering data with the
            # "any_allowed_hash" field omitted. 'nil' values as for 'array'.

            hash :any_allowed_hash

            # A field "specific_allowed_keys" must have a Hash value, which
            # allows only (none or any of) the two listed key names to be
            # valid. ':default' could be used in the 'key' calls to provide
            # a whole-key default value for an omitted key.

            hash :specific_allowed_keys do
              key :allowed_key_one    # Key has any allowed value
              key :allowed_key_two do # Value must match schema in block
                text :field_one
                integer :field_two, :default => 42
              end
            end

            # As above but any keys can be present in the input data. The
            # ':default' option makes no sense for the 'keys' call and its
            # use is prohibited.

            hash :generic_key_description do
              keys :length => 32 do # Keys must be <=32 chars, values must
                                    # match block schema. Block is optional
                                    # - if omitted, any values are allowed.
                text :field_one
                integer :field_two
              end
            end

          end

        end
      end
