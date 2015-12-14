---
layout: default
categories: [guide]
title: Presenters
---

## Purpose

This Guide describes the Hoodoo presentation layer -- a lightweight schema to describe resources for both inbound data validation and outbound data rendering.



## Resource definition

A service implements endpoints for one or more resources. The resources are described by your API, with common fields and behaviour mandated by the [Hoodoo API Specification]({{ site.custom.api_specification_url }}).

Any resource definition that uses the Hoodoo presenter layer is defined as a descendant of `Hoodoo::Presenters::Base` thus:

```ruby
class Foo < Hoodoo::Presenters::Base
  # ...
end
```

### Namespacing

Often a resource will have at least one corresponding class related to its persistence layer, such as the Active Record `Person` example in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html). Defining your resource classes inside a module used purely as a namespace is a good idea to avoid confusion over names. For example, there might be a `Foo` model _and_ resource:

```ruby
class Foo < ActiveRecord::Base
  # ...
end

module Resources
  class Foo < Hoodoo::Presenters::Base
    # ...
  end
end
```

Now, `Foo` will always refer to the model and won't do anything unexpected such as activating namespace extensions inside Active Record, while `Resource::Foo` clearly refers to the Hoodoo resource.

### The schema

Inside any presenter class is a _schema block_ which uses a presenter DSL to describe its contents. The [`schema`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-schema) class method is called with a block, inside which the [DSL methods]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/BaseDSL.html) are called.

```ruby
module Resources
  class Foo < Hoodoo::Presenters::Base
    schema do
      # ...
    end
  end
end
```

### Defaults and requirements

Resource fields can have default values assigned; unless specified, the field has no explicit default. For the purposes of validating the contents of a resource, a field may be marked as required; unless so marked, a field may have no value.



## Rendering

The [`render` method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-render) applies schema defaults to an inbound data set, which in the case of things like the `hash` field type may be quite complex. The result is a ruby `Hash` from an input `Hash` using the schema. For general resource use within a service implementation when a wider request context is available, you should always use the [`render_in` method preferentially]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-render_in).

Rendering rules are:

* Hash keys must all be Strings; Symbols will not be recognised.
* If a field is omitted in the input data Hash, then it only appears in the output if the schema defines a default for it.
* If a field leading to an `object` or `hash` value type is provided as an empty object (`{}`) then default fields/keys from the schema, if any, will be added into that empty object.
* Explicit `nil` means `nil`. If you provide a nil value on input for any field, then it'll be a nil value in the outbound representation. No defaults can override it or appear here. The only exception is attempting to render `nil` overall -- this is basically meaningless, so treated as if you'd tried to render an empty Hash.
* Fields in the input data which are not described in the schema will be stripped out. This includes unrecognised hash keys for hashes which use the `key` DSL method to list one or more specific expected named keys.

```ruby
# Although the DSL accepts Strings or Symbols...

class PresenterClass < Hoodoo::Presenters::Base
  schema do
    object :address do
      text :town
      text :state,   :required => true
      text :country, :default  => 'NZ'
      text :example, :default  => 'nil overrides this default'
    end
  end
end

# ...the renderer only accepts Strings.

data = {
  'address' => {
    'state' => 'Idaho',
    'example' => nil
  }
}

rendered = PresenterClass.render( data )
```

...yields:

```ruby
{
  'address' => {
    'state' => 'Idaho',
    'country' => 'NZ',
    'example' => nil
  }
}
```

> Note that for fields like dates or times, Ruby objects are not accepted; you must provide these as Strings in the input data Hash to `render` and `render_in`. The Ruby `iso8601` method will generate valid results in all cases, but only rounded to integer second accuracy for times; if you want higher precision, see utility method [`nanosecond_iso8601`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-nanosecond_iso8601). For more utility methods related to dates and times, see the [Utilities Guide]({{ site.baseurl }}/guides_0700_utilities.html).



## Manual outbound validation

You may wish to self-check data you are intending to return as the response to an API call, especially in non-production execution modes -- when `Service.config.env.production?` yields `false`.

To do this, call [`validate`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-validate). An array of zero or more validation errors will be returned. This includes globally defined errors such as `generic.required_field_missing` if option `:required => true` is set on a field but a value is not provided for it, along with the various `generic.invalid_...` errors for fields where the value is not of the expected type.

In the schema DSL, field type `string` _requires_ a `:length => <integer>` option and validation will return `generic.max_length_exceeded` if the data exceeds the allowed length. Within hashes, the `key` part of the DSL defines specific named keys expected in the hash, while the `keys` part describes just the generic "shape"/schema of keys (if required) and, like `string`, lets you specify a `:length => <integer>` option if you require that keys in the hash do not exceed a certain length.

`date` and `datetime` are valid if they are [ISO8601](http://en.wikipedia.org/wiki/ISO_8601) subset dates or datetimes respectively, e.g.

* date: `1978-12-24`
* datetime: `1978-12-24T13:24:11Z`, `2014-09-01T12:03:22+12:00`

Validation will check for impossible dates (allowing Feb 29 in leap years), and will accept all timezones including `Z` (Zulu, +00:00 / UTC) for datetimes. See the [Utilities Guide]({{ site.baseurl }}/guides_0700_utilities.html) for more about the underlying permitted ISO 8601 date/time subsets and their validation methods.

> **Important:** During validation, `default` specifiers have **NO EFFECT** since it doesn't make sense to try and apply inbound data defaults during a validation pass. Defaults are only applied during rendering, allowing your underlying data model to potentially have no defaults, with default values entirely in the application layer should you so wish. Alternatively you could use no resource-layer defaults at all and (say) rely entirely on defaults specified for database columns and/or intermediate Ruby models. In a similar vein, for updates, any `required` specifiers **ARE IGNORED** because the typical intent of a `PATCH` is that any omitted fields in the inbound payload simply mean there is no change being requested for that particular field. It's only an error to omit a required field when attempting to _create_ a new instance.

### Render then validate

Default values for fields are only applied when you render something, not when you validate it. For self-checking outbound data, validating data _before_ it goes through the renderer is wrong, because defaults have not been applied yet. You could incorrectly fail your own outbound data self-check because of an omitted value where you might have over-constrained it as both required, but also having a default which wouldn't have yet been applied.

Instead, render first. Taking the earlier `PresenterClass` example for rendering and continuing this with validation:

```ruby
data = {
  'address' => {
    'state' => 'Idaho',
    'example' => nil
  }
}

rendered = PresenterClass.render( data )
validation_errors = PresenterClass.validate( rendered )
```

...yields an empty array -- there are no errors because the input data is valid. We defined the `state` field as mandatory though; if omitted:

```ruby
data = {
  'address' => {
    'example' => nil
  }
}

rendered = PresenterClass.render( data )
validation_errors = PresenterClass.validate( rendered )
```

...yields:

```ruby
[
  {
    "code"      => "generic.required_field_missing",
    "message"   => "Field `address.state` is required",
    "reference" => "address.state"
  }
]
```

Although manual validation of inbound data is an unusual use case -- usually you should lean on Hoodoo for this, as described later -- _if_ you were doing so as part of a resource implementation class, you would use something along the following lines to add the result of validation to the in-compilation outbound response:

```ruby
def create( context )

  # ...validate the data `context.request.body` as above, then...

  context.response.errors.merge!( validation_errors )
  return if context.response.halt_processing?

  # ...else continue...

end
```

* [`response` and its `errors` attribute]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Response.html)
* [`Hoodoo::Errors#merge!`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Errors.html#method-i-merge-21)
* [`halt_processing?`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Response.html#method-i-halt_processing-3F)

The use of `errors.merge!` arises because the presentation engine's validation code generates raw Ruby arrays of error data, rather than a higher level [`Hoodoo::Errors`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Errors.html) instance. This is _not_ idiomatic; typically we would expect to deal with `Hoodoo::Errors` instances and use something like `context.response.add_errors(errors_object)` instead.



## Automatic inbound validation

Hoodoo provides support to validate inbound data using the same schema as for resource definition. Although your service implementations are quite at liberty to use presenter methods, or their own ad hoc schemes to validate inbound body data from API calls in creation and update implementations, using Hoodoo's code where possible is recommended to reduce your maintenance burden and chance of accidental bugs.

The basis of the Hoodoo support is from the following three methods that are used in the _interface class_ in your service that describes your resource's API behaviour:

* [`to_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_create)
* [`to_update`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_update)
* [`update_same_as_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-update_same_as_create)

### Using a whole resource definition

Sometimes, your API will define a resource and all of its fields (apart from the Hoodoo standard common fields) may be writable in a `POST` creation request and, perhaps, even a `PATCH` alteration request.

```ruby
class FooResourceInterface < Hoodoo::Services::Interface
  # ...boilerplate...

  to_create do
    resource PresenterClass
  end
end
```

This leans on previous examples and gives a class reference to the `resource` method of the schema. That class is fetched, its own schema examined and this is unpacked "in place", to become the validation schema for creation actions. In the example above, no on-update schema has been given -- you can either copy the `to_create` block inside a `to_update` block, use the shorthand method `update_same_as_create` or define a new `to_update` block with some schema variation, as described in the next section.

> **Important:** Remember that `required` flags are deliberately ignored within `to_update` blocks. Omission of a field is taken to signify that no change in current value is requested.

### Using bespoke fields

Sometimes, only some of the fields can be specified for creation and update, but others might arise in the resource representation.

As an extreme example, an 'Addition' resource might accept a field `add` with a value that is an array of integers, but when represented (`show` / `GET`) might render as a field `sum` with a value that is just a single integer giving the sum of the input array.

As a less extreme example, suppose a resource accepts `programme_name` and `programme_code` only for creation `POST`s; and only allows subsequent modification of `programme_name` with a `PATCH`. No matter how the whole `Programme` resource associated with the `ProgrammeInterface` given below might look, the validation declaration would be:

```ruby
class ProgrammeInterface < Hoodoo::Services::Interface
  # ...boilerplate...

  to_create do
    text   :programme_name
    string :programme_code, :length => 32
  end

  to_update do
    text :programme_name
  end
end
```

### Resource and type references

The [`resource`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/BaseDSL.html#method-i-resource) and [`type`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/BaseDSL.html#method-i-type) parts of the DSL are described in detail in RDoc. Both methods are usually provided with class references directly -- e.g. `resource( PresenterClass )` -- so that the target class is explicit. Historically it has also been possible to pass a Symbol naming a Type or Resource which is then fetched from a hard-coded Hoodoo-derived namespace, but this is deprecated and discouraged.



## Full schema example

```ruby
module Resources
  class Example < Hoodoo::Presenters::Base
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
      #
      array :array_with_any_values, :default => [ 1, 2, 3 ]

      # Field "objects_with_two_text_fields" must have an Array value,
      # where values are either nil or an object with two text fields
      # "field_one" and "field_two".
      #
      # Example valid input:
      # { 'array_with_values' => [ { 'field_one' => 'one' },
      #                            { 'field_two' => 'two' } ] }
      #
      array :objects_with_two_text_fields do
        text :field_one
        text :field_two
      end

      # A field "any_allowed_hash" must have a Hash value, with any
      # hash contents permitted. 'default' could be used to provide
      # an entire default Hash value for rendering data with the
      # "any_allowed_hash" field omitted. 'nil' values as for 'array'.
      #
      hash :any_allowed_hash

      # A field "specific_allowed_keys" must have a Hash value, which
      # allows only (none or any of) the two listed key names to be
      # valid. ':default' could be used in the 'key' calls to provide
      # a whole-key default value for an omitted key.
      #
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
      #
      hash :generic_key_description do
        keys :length => 32 do # Keys must be <=32 chars, values must
                              # match block schema. Block is optional
                              # - if omitted, any values are allowed.
          text :field_one
          integer :field_two
        end
      end

    end # 'schema do'
  end   # 'class Example < Hoodoo::Presenters::Base'
end     # 'module Resources'
```
