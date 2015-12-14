---
layout: default
categories: [guide]
title: Active Record Integration
---

## Purpose

Hoodoo services can use any persistence mechanism they like. For databases, [Active Record](http://guides.rubyonrails.org/active_record_basics.html) tends to be the most widely used and developed interface thanks to Ruby On Rails. This Guide describes a set of mixins that make it much, much easier to use Active Record in services and help out with common pitfalls such as a concurrency safety across multiple independent service processes.

* [Active Record Basics at RailsGuides](http://guides.rubyonrails.org/active_record_basics.html)
* [Active Record ReadMe](https://github.com/rails/rails/tree/master/activerecord)



## By example

> The finished example service, including all the migrations / dating extensions described later, is available in [this archive]({{ site.baseurl }}/examples/service_person.zip).

Make sure you have the `hoodoo` binary available -- on Mac OS X with `rbenv` you'll probably see output like this:

```sh
$ which hoodoo
/Users/someone/.rbenv/shims/hoodoo
```

If the command isn't found, make sure `gem install hoodoo` has been run. Create `service_person` from the Hoodoo service shell and install its dependencies with:

```sh
hoodoo service_person
cd service_person
bundle install
```

Inspect `config/database.yml` and see if any changes are needed. Since this is used by ActiveRecord, the options and behaviour are exactly the same as for a Rails application. If you have PostgreSQL installation running which accepts localhost connections, it should need no changes.

> You don't have to use PostgreSQL unless you want to use the [historical dating facilities described later](#Dating). Those only work with PostgreSQL.

When you're happy with the database and configuration, create your empty development mode database:

```sh
bundle exec rake db:create
```

### Migrations and `id`

Consider a simple case where a single Active Record model of `Person` is used to store the representation of a `Person` resource. Create an empty migration file using this command:

```sh
bundle exec rake g:migration NAME=create_people
```

The code for this defines the `Person` _model_ **and uses the recommended way to define an `id` column**:

```ruby
class CreatePeople < ActiveRecord::Migration
  def self.up

    # Note important use of ":id => :string" to define a
    # non-numeric primary key that can accept a UUID.
    #
    create_table :people, :id => :string do | t |
      t.string :name, :null => false
      t.date   :date_of_birth

      t.timestamps :null => false
    end

    # Limit the primary key to the maximum UUID length of 32
    # characters, to help the database work more efficiently.
    #
    change_column :people, :id, :string, :limit => 32

  end

  def self.down
    drop_table :people
  end
end
```

Since Hoodoo uses UUIDs for instances we don't use a database sequence for the `id` column. We let ActiveRecord use `id` as the primary key as usual, but we set the data type to `string`. This works but is inefficient, as the database will assign its default maximum string length to the column; so the subsequent `change_column` statement, while strictly optional, is highly recommended. We end up with a string primary key of as close to the 'correct' type inside the database as the database adapter allows, restricted to just the right length for a Hoodoo UUID.

Purely for this example, the `name` field must be present too -- "`:null => false`" is specified. The Rails-like timestamp specification is useful and essential for [historical dating support (see later)](#Dating). Adding database-level constraints is important for concurrency and you should always specify things at the data layer as tightly as possible.

Run the migration with:

```sh
bundle exec rake db:migrate
```

Examining the resulting table in (say) PostgreSQL at the `psql` command line yields:

```
service_person_development=# \d+ people
                                      Table "public.people"
    Column     |            Type             | Modifiers | Storage  | Stats target | Description
---------------+-----------------------------+-----------+----------+--------------+-------------
 id            | character varying(32)       | not null  | extended |              |
 name          | character varying           | not null  | extended |              |
 date_of_birth | date                        |           | plain    |              |
 created_at    | timestamp without time zone | not null  | plain    |              |
 updated_at    | timestamp without time zone | not null  | plain    |              |
Indexes:
    "people_pkey" PRIMARY KEY, btree (id)
```

* The database has correctly identified `id` as a primary key and automatically indexed it accordingly.
* The 32 character length constraint is set.
* The `not null` constraint is present for `name` and the timestamps.

### Enabling `racksh`

The low level Rack equivalent of the Rails console is `racksh`. This is an interactive Ruby shell like `irb`, but with all of your service code loaded into it. It uses a [gem called `pry`](https://github.com/pry/pry) to provide very expanded abilities on top of the basic Ruby prompt. It is very helpful to get this going as soon as possible when developing new service code.

We need to set up an empty skeleton of a service before we can boot this up, so create a file called `service/interfaces/person_interface.rb` and write a very simple interface class that makes a full set of CRUD actions public so we don't have to worry about session management for this example:

```ruby
class PersonInterface < Hoodoo::Services::Interface
  interface :Person do
    endpoint :people, PersonImplementation
    public_actions :show, :list, :create, :update, :delete
  end
end
```

This will mount the resource at a path of `.../v1/people`. The filename can be anything you like, but using a name derived from a prefix of the associated resource's name and a suffix which tells you what the file is for (e.g. interface, implementation, resource, model) helps avoid confusion when moving between files in a text editor.

Next create file `service/implementations/person_implementation.rb` and put a stub in there for now:

```ruby
class PersonImplementation < Hoodoo::Services::Implementation
end
```

Finally, point the top-level `service.rb` at the `PersonInterface` class. When you load this file you will see it raises a warning exception and has a commented out `comprised_of` example line. Delete the warning and fill in the `comprised_of` so that `service.rb` now looks like this:

```ruby
class ServiceApplication < Hoodoo::Services::Service
  comprised_of PersonInterface
end
```

Now you have a very minimal service with just a single resource endpoint that contains a dummy endpoint. This is enough to get all the Hoodoo middleware up and running so `racksh` can start up properly:

```sh
bundle exec racksh
```

You can now interact with your classes. For example:

```
$ bundle exec racksh
Loading development environment
Rack::Shell v1.0.0 started in development environment.
[1] pry(main)> PersonInterface.version
=> 1
[2] pry(main)> PersonInterface.endpoint
=> :people
```

### Models

To keep things simple, you can define a model class that inherits from `Hoodoo::ActiveRecord::Base`. This means all Hoodoo Active Record support mixins will be included automatically. You can, if you prefer, just inherit from `ActiveRecord::Base` normally and include mixins manually. The most minimal example with all mixins is:

```ruby
class Person < Hoodoo::ActiveRecord::Base
  validates :name, :presence => true
end
```

Create a file `service/models/person_model.rb` with the above contents and that's it -- the model is ready. Note that as before, you can use any filename you like, but the `<name>_<purpose>.rb` approach is recommended to make life easier when editing code. To play around with the model using the command line, launch `racksh`:

```sh
bundle exec racksh
```

...and then issue Ruby statements like `Person.new` to see that there's nothing special going on; it's just the familiarity of Active Record. The higher level abstractions described herein, though, are **very strongly recommended** when writing service code.

```
$ bundle exec racksh
Loading development environment
Rack::Shell v1.0.0 started in development environment.
[1] pry(main)> p = Person.new
=> #<Person:0x007f98aba7cb28 id: nil, name: nil, date_of_birth: nil, created_at: nil, updated_at: nil>
[2] pry(main)> p.save!
ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

You can see all the module inclusions [in the Hoodoo source code](https://github.com/LoyaltyNZ/hoodoo/blob/master/lib/hoodoo/active/active_record/base.rb). These are all described in detail later; in brief:

* The Secure mixin applies scoped access rules to lookups.
* The Dated mixin allows a resource to track its changes over time.
* The Translated mixin supports multiple languages.
* The Finder mixin relies upon the above to provide data reading support.
* The UUID mixin automatically assigns and validates a Hoodoo UUID into the `id` column.
* The Writer mixin provides concurrency-safe data writing support.
* The Error Mapping mixin translates between Active Record attribute-level errors and Hoodoo platform errors.

### The resource

Use of the Hoodoo presenter layer [(see Presenters Guide)]({{ site.baseurl }}/guides_0400_presenters.html) for sending back correct resource representations to API callers is recommended. We want a `Person` resource to go with the `Person` model, but Hoodoo and Active Record conventions on class names interfere a little here. Hoodoo uses the class name to infer the resource name when rendering, while Active Record infers table names and the like. To keep things simple, just namespace your resource classes with a module called -- say -- `Resources`. Anything will do, at any level of nesting; Hoodoo just looks at the "leaf" class name. In this simple example, create a file `service/resources/person_resource.rb` and add the following:

```ruby
module Resources
  class Person < Hoodoo::Presenters::Base
    schema do
      string :name, :required => true, :length => 256
      date   :date_of_birth
    end
  end
end
```

You could use a namespace module for consistency with your Active Record models too, but Active Record will start to treat the namespace as significant in that case and this can cause worlds of pain, especially with associations. In any case, it leads to rather unnatural looking code for Active Record normal use; `Foo.something` is commonplace, while `Models::Foo.something` is relatively unusual.

There is no need for the data model layer to have a very similar definition to the resource layer, but that's often the case. Simple mappings reduce the chance of bugs when taking `POST` or `PATCH` fields and persisting them, or when presenting persisted model data as a resource. More complex resources, though, may involve unusual mappings or even multiple models connected via familiar Active Record constructs such as `belongs_to` or `has_one`.

### Using validation

You can prove the resource is working by playing around with [low-level validation]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-validate) using `racksh`:

```
$ bundle exec racksh
Loading development environment
Rack::Shell v1.0.0 started in development environment.
[1] pry(main)> Resources::Person.validate( {} )
=> [{"code"=>"generic.required_field_missing", "message"=>"Field `name` is required", "reference"=>"name"}]
[2] pry(main)> Resources::Person.validate( { 'name' => 'Alice' } )
=> []
[3] pry(main)> Resources::Person.validate( { 'name' => 'Alice', 'date_of_birth' => 'not_a_date' } )
=> [{"code"=>"generic.invalid_date", "message"=>"Field `date_of_birth` is an invalid ISO8601 date", "reference"=>"date_of_birth"}]
[14] pry(main)> Resources::Person.validate( { 'name' => 'Alice', 'date_of_birth' => ( Date.today - 20.years ).iso8601() } )
=> []
```

Given ActiveRecord validation, what is resource validation for? Without any resource-level validation, then if someone were to try to `POST` to create a new Person resource instance without a name, a well-formed Errors instance would be returned saying that the `name` field is required -- but _this comes from Active Record_ and the Hoodoo mixin which maps Active Record model validation errors to Hoodoo platform errors. However:

* We didn't add an Active Record validation on the date field, so if someone were to `POST` with a malformed date we would probably get a database exception reported back via an Errors instance.

* If your data model were quite different from resource representation, the names of fields reported by Active Record validation errors, should things go that far, might not make sense to resource-based API callers even if Hoodoo converts them to higher-level validation error representations.

* Arbitrary body properties for `POST` or `PATCH` operations could be specified and the service might have to do work to filter those out to avoid nasty errors or potential vulnerabilities, depending on the mappings between model and resource.

Aside from ensuring good database constraint and Active Record validation coverage as a matter of good practice, we can use any presenter schema for validation of `create` and/or `update` payloads as an additional first line of defence. In this simple example, the permissable body for both of those actions is the same and it matches the schema already described by `Resources::Person`. This makes life easy. In `service/interfaces/person_interface.rb`, change the interface as follows:

```ruby
class PersonInterface < Hoodoo::Services::Interface
  interface :Person do
    endpoint :people, PersonImplementation
    public_actions :show, :list, :create, :update, :delete

    to_create do
      resource Resources::Person
    end

    update_same_as_create
  end
end
```

Now, Hoodoo JSON-level validation will happen first, providing the best opportunity for descriptive, detailed errors about any payload problems. Next, Active Record validation errors get mapped as best as possible. Finally, database level exceptions might still happen if application-level checks fail (usually due to concurrent call race conditions) and uncaught constraint violations are encountered by the database. For more, see:

* [`to_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_create)
* [`to_update`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_update)
* [`update_same_as_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-update_same_as_create)



### The service implementation

It is time to replace the stub written earlier into `service/implementations/person_implementation.rb`.

#### Show

```ruby
class PersonImplementation < Hoodoo::Services::Implementation

  def show( context )
    person = Person.acquire_in( context )

    if person.nil?
      context.response.not_found( context.request.ident )
    else
      context.response.set_resource( render_in( context, person ) )
    end
  end
```

The Finder mixin method [`acquire_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire_in) is used to retrieve based on any lookup parameters defined by the model, coupled with any security, dating or translation aspects which might be in use. In this example we aren't doing anything special but the idiomatic pattern is easy to use in any event.

The convenience method of [`not_found`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Response.html#method-i-not_found) is used on the [`response` object]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Context.html) to easily add an appropriately well formed error if we cannot find the requested instance, else it is set as the response data via a private renderer method you'll see at the end of the class.

To provide a value for `set_response`, a private convenience method `render_in` is called. Its definition is shown later.

#### List

```ruby
  def list( context )
    finder = Person.list_in( context )
    list   = finder.all.map { | person | render_in( context, person ) }

    context.response.set_resources( list, finder.dataset_size )
  end
```

The Finder mixin method [`list_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-list_in) is used to retrieve a list of persisted model data, with searching/filtering, pagination and sorting all handled automatically. The returned value is an [`ActiveRecord::Relation`](http://api.rubyonrails.org/classes/ActiveRecord/Relation.html) so additional Active Record methods such as `where` may be chained onto the end manually. The same rendering call as used for `show` above is run over each result in that 'page'.

> At the time of writing Hoodoo doesn't restrict requested page sizes, so an API caller could ask for a giant list. Consider manually restricting that by adding code at the start of your `list` implementation -- e.g. `context.request.list.limit = 1000 if context.request.list.limit > 1000` -- with `1000` being a number you could tune according to your model and resource representation sizes, acceptable maximum memory usage and so-forth.

The call to [`dataset_size`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-dataset_size) returns the total number of results that would be present _without_ pagination (you can't just `count` on the `finder` scope, because that's already `limit`-ed).

#### Create

```ruby
  def create( context )
    person = Person.new_in( context, context.request.body )

    unless person.persist_in( context ) === :success
      context.response.add_errors( person.platform_errors )
      return
    end

    context.response.set_resource( render_in( context, person ) )
  end
```

Here we take advantage of the similarity between resource and model attributes and just pass the body data from the request straight through. We have specified resource-level validation in the interface class, so Hoodoo will have sanitised the input already. Depending on your own data model to resource mappings, permitted `POST` body contents and so-on, your code may be equally straightforward or much more complex.

> The UUID of a resource is usually assigned by the [Hoodoo::ActiveRecord::UUID mixin]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/UUID.html). You can manually assign values to the `id` column if you wish; in particular, if you manually map inbound body fields to model attributes, you really _should_ include `id` from the inbound body data to the appropriate "primary" model's `id` field so that lookups based on that request-specified ID will find the "right thing". This is how you support the [`X-Resource-UUID` header]({{ site.custom.api_specification_url }}#http_x_resource_uuid) -- addition of `id` into the inbound request body is the route for delivery of the specified value. This secured, special HTTP header is only examined for `POST` requests and only allowed if the caller's session states that it is permitted. It is **recommended** that this header be supported by services. In the example code case, we just map the inbound request body wholesale, so this will acquire a value for `id` "for free" if present in the request.

The use of [`new_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Creator/ClassMethods.html#method-i-new_in) is not essential here, but is recommended as a habitual pattern as it could be useful when you add features to your existing code or Hoodoo adds new features into the Active Record support code. It is also _essential_ if you use the [historical ("effective") dating system](#Dating).

The use of [`perist_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer.html#method-i-persist_in) is very important. This is a very safe way to save data that avoids a few traps for the unwary in high concurrency situations. Please see the [RDoc description of the equivalent class method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer/ClassMethods.html#method-i-persist_in) for details.

```ruby
  def update( context )
    person = Person.acquire_in( context )

    if person.nil?
      context.response.not_found( context.request.ident )
      return
    end

    person.assign_attributes( context.request.body )

    unless person.persist_in( context ) === :success
      context.response.add_errors( person.platform_errors )
      return
    end

    context.response.set_resource( render_in( context, person.reload ) )
  end
```

The `update` implementation starts rather like `show` and ends rather like `create`. You can update attributes from the body of the request in _almost_ any way you like, but should still ultimately call `persist_in` at the point you want to write to the database. Here, we're using Active Record's [`assign_attributes`](http://api.rubyonrails.org/classes/ActiveRecord/AttributeAssignment.html#method-i-assign_attributes).

Note the use of `.reload` in the rendering line at the end, to make sure we get any updates resulting from the save; since our example Person migration uses `t.timestamps`, an `updated_at` change would have happened, though this might not be rendered as part of the associated resource's representation and thus may not be important to you. Whether or not you _need_ to call `reload` like this will depend upon your specific models and resources, but if you don't mind the overhead it is recommended habitually to prevent potential bugs with future resource representation updates that might unwittingly introduce a dependency on the reload having happened.

The last public action method is `delete`:

```ruby
  def delete( context )
    person = Person.acquire_in( context )

    if person.nil?
      context.response.not_found( context.request.ident )
      return
    end

    rendered = render_in( context, person )
    person.delete()

    context.response.set_resource( rendered )
  end
```

The [Hoodoo API Specification]({{ site.custom.api_specification_url }}) states a principle of "all-responses representation"; a successful response gives the representation of the resource in question. Accordingly, we render the resource representation to a temporary variable before model deletion and respond with the pre-deletion representation.

The API specification also mentions the `X-Deja-Vu` HTTP header which, if used, tells Hoodoo that an action might have occurred previously. Internally, for deletions, Hoodoo looks for a 'not found' response from a resource implementation and if it sees one, in the presence of the `X-Deja-Vu: yes`, will turn this into an HTTP 204 response instead. There is an opportunity, should two people independently delete the same resource instance at the same time with at least two processes running servers for that resource endpoint, for race conditions. Both processes may find the resource before either deletes it, then both try to delete it. With the code shown above this will have no undesirable side effects and both calls will appear to succeed. Other Active Record approaches to deletion _might_ raise exceptions or other errors should a delete be attempted for a no-longer-existing resource instance; beware.

When it comes to deletion methods, the use of Active Record's `delete` method here means [callbacks are not run](http://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-delete); generally callbacks are something of an anti-pattern and discouraged. If you _do_ use them though don't forget to use something like the Active Record [`destroy` method](http://api.rubyonrails.org/classes/ActiveRecord/Persistence.html#method-i-destroy) instead of `delete`, though this might mean you have extra return values or exceptions to deal with.

Finally, here is the aforementioned private method `render_in`:

```ruby
private

  # This avoids code duplication between the action methods,
  # concentrating the call to Hoodoo's presenter layer and
  # the database-to-resource mapping into one place.
  #
  def render_in( context, person )
    resource_fields = {
      'name' => person.name
    }

    if person.date_of_birth.present?
      resource_fields[ 'date_of_birth' ] = person.date_of_birth.iso8601()
    end

    options = {
      :uuid       => person.id,
      :created_at => person.created_at
    }

    Resources::Person.render_in(
      context,
      resource_fields,
      options
    )
  end

end # From 'class PersonImplementation < Hoodoo::Services::Implementation'
```

The private `render_in` method is just a veneer over the [same-named class method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html#method-c-render_in) in the resource class we defined earlier which inherited from [`Hoodoo::Presenters::Base`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Presenters/Base.html) -- see the [Presenters Guide]({{ site.baseurl }}/guides_0400_presenters.html) for full details.

### Make some API calls

Run the service on localhost with `rackup`:

```
$ bundle exec rackup
Loading development environment
[2015-11-30 10:25:35] INFO  WEBrick 1.3.1
[2015-11-30 10:25:35] INFO  ruby 2.2.3 (2015-08-18) [x86_64-darwin15]
[2015-11-30 10:25:35] INFO  WEBrick::HTTPServer#start: pid=7798 port=9292
```

In this case the service has started up on the default [WEBrick](http://ruby-doc.org/stdlib-2.2.0/libdoc/webrick/rdoc/WEBrick.html) port of 9292.

In another shell, talk to this using `curl`. In all examples, the JSON responses back from the command are pretty-printed for legibility here. In reality, a terse, single-line representation is typically returned to be more efficient "on the wire".

> You can also use `bundle exec guard` to bring up your service on a randomised spare port and automatically restart when important files are changed. The command line examples here rely on the predictable port number from `rackup`, though.

#### List people

##### A well-formed call

```sh
curl http://localhost:9292/v1/people \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "_data": [],
  "_dataset_size": 0
}
```

There are no people yet, so the result is an empty list.

##### Making an error in code

If there was anything wrong with the service components you put together from the example above, you'll already know by now that exceptions in the code are reported via a `platform.fault` (HTTP 500) response, with the full backtrace of the exception in the `reference` part of the sole `errors` array entry in non-production environments. In production environments, only the exception message is included, without a backtrace.

##### Making an error as a caller

The most common mistake for API calls is to omit the `Content-Type` header. A well-formed errors instance is returned:

```sh
curl http://localhost:9292/v1/people
```

```json
{
  "created_at": "2015-11-29T21:45:25Z",
  "errors": [
    {
      "code": "platform.malformed",
      "message": "Content-Type '<unknown>' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'"
    }
  ],
  "id": "e9ccd9759f294523b6f5b11c3b536453",
  "interaction_id": "5decf1a2532743309b47a84835e0a73d",
  "kind": "Errors"
}
```

#### Create a new Person instance

We use the `X-Resource-UUID` HTTP header here so that the UUIDs you will get if you copy and paste `curl` commands will match the examples here, minimising the changes needed to make the copied example commands work. **Normally this header would never be used!** The development service for the Person resource runs by default with Hoodoo's standard test session though; it permits the header's use.

> If you run the creation call below twice you will of course get an error because of the attempt to create another instance with the same UUID. When in doubt, use `bundle exec rake db:drop db:create db:migrate" to clean out your development database completely.

```sh
curl http://localhost:9292/v1/people \
     --data '{"name":"Alice"}' \
     --header "Content-Type: application/json; charset=utf-8" \
     --header "X-Resource-UUID: 444da4986d704f1d827116e90d8b6bb1"
```

```json
{
  "created_at": "2015-11-29T21:59:35Z",
  "id": "444da4986d704f1d827116e90d8b6bb1",
  "kind": "Person",
  "name": "Alice"
}
```

Note the resource's UUID in the `id` field.

##### Making an error as a caller

Here, we miss off the mandatory `name` field _and_ specify a bad date, we get back a well-formed platform Errors resource instance with validation failure information for both problems:

```sh
curl http://localhost:9292/v1/people \
     --data '{"date_of_birth":"yesterday"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T23:35:52Z",
  "errors": [
    {
      "code": "generic.required_field_missing",
      "message": "Field `name` is required",
      "reference": "name"
    },
    {
      "code": "generic.invalid_date",
      "message": "Field `date_of_birth` is an invalid ISO8601 date",
      "reference": "date_of_birth"
    }
  ],
  "id": "a92a1e09157147a8956e4b5b7a349ecb",
  "interaction_id": "3c0db4c7317d4b68918a1d5ef0d60eb0",
  "kind": "Errors"
}
```

Both of these are Hoodoo-level validation failures because the [`to_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_create) block describing the acceptable JSON schema was added into the interface class earlier.

#### Show the Person instance

We use the UUID from the successful earlier creation in the URI of a `GET` request to fetch a representation of that instance:

```sh
curl http://localhost:9292/v1/people/444da4986d704f1d827116e90d8b6bb1 \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T21:59:35Z",
  "id": "444da4986d704f1d827116e90d8b6bb1",
  "kind": "Person",
  "name": "Alice"
}
```

#### Change the Person instance's `name`

We use the instance UUID in the URI of a `PATCH` request too:

```sh
curl http://localhost:9292/v1/people/444da4986d704f1d827116e90d8b6bb1 \
     --request PATCH \
     --data '{"name":"Alice Smith"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T21:59:35Z",
  "id": "444da4986d704f1d827116e90d8b6bb1",
  "kind": "Person",
  "name": "Alice Smith"
}
```

#### List all Person instances again

```sh
curl http://localhost:9292/v1/people \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "_data": [
    {
      "created_at": "2015-11-29T21:59:35Z",
      "id": "444da4986d704f1d827116e90d8b6bb1",
      "kind": "Person",
      "name": "Alice Smith"
    }
  ],
  "_dataset_size": 1
}
```

#### Unrecognised fields are rejected with Hoodoo validation

Since we specified resource-level validation via [`to_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_create) etc., Hoodoo prohibits attempts to create or modify records with unrecognised fields. First, `POST`:

```sh
curl http://localhost:9292/v1/people \
     --data '{"name":"Alice 2", "something":"unrecognised"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T23:36:01Z",
  "errors": [
    {
      "code": "generic.invalid_parameters",
      "message": "Body data contains unrecognised or prohibited fields",
      "reference": "something"
    }
  ],
  "id": "56114239f0fb490c865625c0ba124dd5",
  "interaction_id": "436e95522abc459ea667939639ad67bc",
  "kind": "Errors"
}
```

Next, `PATCH`:

```sh
curl http://localhost:9292/v1/people/444da4986d704f1d827116e90d8b6bb1 \
     --request PATCH \
     --data '{"something":"unrecognised"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T23:36:04Z",
  "errors": [
    {
      "code": "generic.invalid_parameters",
      "message": "Body data contains unrecognised or prohibited fields",
      "reference": "something"
    }
  ],
  "id": "94356a495a8144f8a8692d8924b837c3",
  "interaction_id": "68d28f7fc1a249ac87b792aec7c83625",
  "kind": "Errors"
}
```

#### Delete the Person instances

Using a `DELETE` request with the UUID in the URI deletes the resource but, as expected, responds with a representation of that resource instance's state prior to deletion:

```sh
curl http://localhost:9292/v1/people/444da4986d704f1d827116e90d8b6bb1 \
     --request DELETE \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-29T21:59:35Z",
  "id": "444da4986d704f1d827116e90d8b6bb1",
  "kind": "Person",
  "name": "Alice Smith"
}
```

#### List again

The list is now empty:

```sh
curl http://localhost:9292/v1/people \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "_data": [],
  "_dataset_size": 0
}
```



## In detail

This section leans on RDoc references as far as possible.

### Reading data

#### Finder

The [Finder]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder.html) class with its various [class methods]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html) forms the basis of the recommended Hoodoo data retrieval mechanism.

##### Find one

Methods [`acquire`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire) and [`acquire_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire_in) find a single instance of a resource. These both allow for a facility wherein a resource might be retrievable by UUID, or by some other unique identifiers. For example, you might have a resource representing some kind of uniquely numbered loyalty card and allow it to be retrieved either by the card UUID or, for convenience of most callers, the loyalty card number. In the _Active Record model_ you can declare a list of one or more other attributes that will be queried for a match to the identifier passed in from an external API call to your resource.

The `acquire_in` method **is the recommended way** to look up one item -- it understands security. It is backed by `acquire` but does other security actions too. The combination of security layer plus "polymorphic" finding gives a very useful safety net over just using Active Record's native `find`, or one of the variants.

##### Find many -- search, filter

Methods [`list`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-list) and [`list_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-list_in) find lists of resources, with automatic support for searching/filtering, ordering and pagination based on standardised query string parameters described by the [Hoodoo API Specification]({{ site.custom.api_specification_url }}). A resource _interface class_ declares one or more permitted search and/or filter query string keys via the [`to_list`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_list) method and block, then an _Active Record model_ states how those keys map to actual queries. RDoc has a _lot_ of information about this, so be sure to follow the above links for more information.

If you add new searchable columns, don't forget to generate migrations adding database indices:

```sh
bundle exec rake g:migration NAME=add_index_to_name
```

```ruby
class AddIndexToName < ActiveRecord::Migration
  def up
    add_index :people, :name
  end

  def down
    drop_index :people, :name
  end
end
```

Sorting is managed purely by the resource's interface class at present, with no ability at the time of writing to decouple the inbound sort order key from the model attribute used for sorting -- they must have the same name.

As with `acquire_in`, [`list_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-list_in) **is the recommended way** to obtain lists of model instances, as you then benefit from things like the security layer (see below) or any other included mixins that might be involved in the listing chain.

###### Example

Hoodoo's search and filter facilities are quite simple and you might want to define search/filter keys in your resource's interface class which go beyond things that are possible using the associated Active Record mapping. You can bypass, or combine the two in your implementation. In this example, we search the Person resource by any part of their name or by their _year_ of birth and, for sake of example, will handle the name with Hoodoo and the year inside the service manually.

Since we know we will be searching internally on columns `name` and `date_of_birth` one way or another, we need to add database indices for that.

```sh
bundle exec rake g:migration NAME=add_search_indices
```

Edit the resulting file in `db/migrate`:

```ruby
class AddSearchIndices < ActiveRecord::Migration
  def up
    add_index :people, :name
    add_index :people, :date_of_birth
  end

  def down
    drop_index :people, :name
    drop_index :people, :date_of_birth
  end
end
```

Run the migration:

```sh
bundle exec rake db:migrate
```

We declare the ability to search on those keys in the Person Resource's _interface_. We'll define URI search query string entries of `partial_name` and `birth_year`.

```ruby
class PersonInterface < Hoodoo::Services::Interface
  interface :Person do

    # ...as already shown earlier, then add...

    to_list do
      search :partial_name, :birth_year
    end
  end
end
```

The Person _model_ will define a database agnostic, case insensitive, full wildcard search for the `partial_name` key only, using the Hoodoo supported mechanism.

```ruby
class Person < Hoodoo::ActiveRecord::Base
  dating_enabled
  validates :name, :presence => true

  search_with( {
    :partial_name => Hoodoo::ActiveRecord::Finder::SearchHelper.ciaw_match_generic( :name )
  } )
end
```

Here, one of the out-of-the-box `Proc`s declared in [`Hoodoo::ActiveRecord::Finder::SearchHelper`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Finder/SearchHelper.html) is used to match up a value from query string key `partial_name` against a generic (database agnostic) case-insensitive all-wildcard match to column `name`. That's all we need to do for Hoodoo-supported searching -- we can test this right away. Bring up the service and create four Person instances:

```sh
bundle exec rackup
```

```sh
curl http://localhost:9292/v1/people \
     --data '{"name":"Alice One","date_of_birth":"1975-03-01"}' \
     --header "Content-Type: application/json; charset=utf-8"

curl http://localhost:9292/v1/people \
     --data '{"name":"Alice Two","date_of_birth":"1984-09-04"}' \
     --header "Content-Type: application/json; charset=utf-8"

curl http://localhost:9292/v1/people \
     --data '{"name":"Bob One","date_of_birth":"1975-11-23"}' \
     --header "Content-Type: application/json; charset=utf-8"

curl http://localhost:9292/v1/people \
     --data '{"name":"Bob Two","date_of_birth":"1956-02-01"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

List all the "alices":

```sh
curl http://localhost:9292/v1/people?search=partial_name%3Dalice \
     --header "Content-Type: application/json; charset=utf-8"
```

Abridged response (common fields like `id` etc. have been omitted for brevity):

```json
{
  "_data": [
    { "name": "Alice Two" },
    { "name": "Alice One" }
  ],
  "_dataset_size": 2
}
```

List everyone with an 'E' in their name (so that'll be everyone except 'Bob Two'):

```sh
curl http://localhost:9292/v1/people?search=partial_name%3DE \
     --header "Content-Type: application/json; charset=utf-8"
```

Abridged response:

```json
{
  "_data": [
    { "name": "Bob One"   },
    { "name": "Alice Two" },
    { "name": "Alice One" }
  ],
  "_dataset_size": 3
}
```

Next, wire up the `birth_year` search parameter through the implementation. Inside the implementation class `list` method:

```ruby
  def list( context )
    finder     = Person.list_in( context )
    birth_year = context.request.list.search_data[ 'birth_year' ].to_i

    unless birth_year.zero?
      this_year_start = Date.new( birth_year     )
      next_year_start = Date.new( birth_year + 1 )

      # Note inclusive start, exclusive end date range.
      #
      finder = finder.where( :date_of_birth => ( this_year_start ... next_year_start ) )
    end

    list = finder.all.map { | person | render_in( context, person ) }

    context.response.set_resources( list, finder.dataset_size )
  end
```

Since the result of `list_in` is just a scope, additional clauses can be chained on. So, having called `list_in`, we can see if there is a birth year search being requested too and if so, add the appropriate `where` call. In the event that the order of the call in the chain happens to matter, you may choose to generate a scope using normal Active Record methods first and then call `list_in` on that in-progress scope. Example pseudocode:

```ruby
finder = Person.where( ... ).order( ... ).list_in( context )
```

The new search parameter is now ready to use. Given the four Person instances created earlier, list all born in 1975 (expecting Alice and Bob One):

```sh
curl http://localhost:9292/v1/people?search=birth_year%3D1975 \
     --header "Content-Type: application/json; charset=utf-8"
```

Abridged response for brevity, as earlier:

```json
{
  "_data": [
    { "name": "Bob One"   },
    { "name": "Alice One" }
  ],
  "_dataset_size": 2
}
```

List all Alices born in 1975:

```sh
curl http://localhost:9292/v1/people?search=partial_name%3Dalice%26birth_year%3D1975 \
     --header "Content-Type: application/json; charset=utf-8"
```

Abridged response:

```json
{
  "_data": [
    { "name": "Alice One" }
  ],
  "_dataset_size": 1
}
```

The two search terms are working together as expected.

Exclusion, rather than inclusion, can be achieved by using `filter_with` in the same way as `search_with` in the Active Record model, or looking at `filter_data` instead of `search_data` inside the resource implementation if you're handling the parameter manually.

##### Test-Driven Development

For brevity in this example, the focus has been on writing idiomatic, simple implementation code and demonstrating the results quickly with `curl`. A better approach for a real service would be to write tests before the implementation (in the wider sense). Whatever development approach you favour, you should certainly good write test coverage whether before or after the fact, as per the [Testing Guide]({{ site.baseurl }}/guides_0900_testing.html). That guide includes an example which adds some tests to `service_person`.

#### Security

A lot of security information is covered in the [Security Guide]({{ site.baseurl }}/guides_0200_security.html), but that Guide defers to this one for information about Active Record.

The underpinnings of the data access security layer for Active Record are held in the [Secure mixin]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Secure.html). Extensive documentation for this is in the RDoc documentation for the mixin class methods, [especially the `secure` method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Secure/ClassMethods.html#method-i-secure). Reading this carefully is **very strongly encouraged**. Although it leaves this important section of the guide looking rather empty, the RDoc information has everything you need to know including example code, so there is no need to copy it all here.

When you use the likes of `acquire_in` or `list_in` (see earlier), the scope is built up using `secure` as part of the scope when the mixin is present, so all of the described facilities come into play **automatically and implicitly**. There's no opportunity to accidentally forget to call `secure` anywhere and leak data.

#### <a name="Dating"></a>Dating

> Advanced topic. Dating support only works with the PostgreSQL database, version 9.3 or later.

Normally with Active Record, when attributes of a model are updated, the row representing that model in the database is changed with no permanent record of its previous state. Likewise, if a row is deleted from the database, there is no record kept of its previous state or even that it ever existed.

Sometimes you want some kind of audit trail or change recording. Various gems exist to provide different kinds of change tracking / auditing and you can use those if you wish. Hoodoo itself -- supported by complex migrations in the service shell -- provides full historical dating and recovery support for the entire change history of a model instance. The feature is sometimes referred to as "Effective Dating", in reference to being able to retrieve the "effective state" of an object from any date in its lifecycle.

> With historically dated resources, **there is no true delete**. Historical records always remain. Bear this in mind when considering data retention and privacy policies for your API!

The change recording process works like this:

* When an object is created, its creation time is stored. It exists in the database table you expect according to your conventional Active Record and model configuration.

* If the object is modified, a copy of its old state is made in a history table for the model in question. This is done by a PostgreSQL database trigger and is transparent to the application, which just saves the updated record in the normal fashion.

* History table entries are made for every update. The model's main table only ever contains the most up to date version.

* If the record is eventually deleted, its entry is moved from the main table to the history table. No record remains in the main table, but all of its associated history table rows are preserved forever.

Retrieval is always done in the context of a date:

* If you try to find a model instance (a row in the main table) without a date (for example by a normal Active Record `find` call) then the lookup happens in the main table as normal, so finds the most recent version -- or no version, if something was deleted -- of the requested item(s) by default.

* When Hoodoo retrieval mechanisms described here are used without a date, "now" is specified by the Hoodoo code running in the **service** so the read and write date/times will consistently come from either the application layer or be specified by an API call.

* Whether the retrieval date is "now" or explicitly specified, if using the Hoodoo retrieval mechanisms, the state of the model at that time is returned either from the history table or the main table as required. If the retrieval time given is from before the original creation date of the entry, then it acts as if it is not found; likewise if the entry was eventually deleted and only exists in the history table, then attempts to retrieve its state from a later time will also behave as if the row isn't found.

For performance reasons and for transparency reasons, as much as possible of this is done by the database and that's why at present the implementation is heavily tied into just one database -- PostgreSQL 9.3 or later. It is probably no surprise to learn that there is quite a lot of setup needed for this, but fortunately an awful lot if it is handled by a migration generator built into the [Service Shell](https://github.com/LoyaltyNZ/service_shell). You should [read the comments in this](https://github.com/LoyaltyNZ/service_shell/blob/master/bin/generators/classes/effective_date_class.rb) to find out how to use it and, if curious, take a look at the [templates it uses](https://github.com/LoyaltyNZ/service_shell/tree/master/bin/generators/templates/effective_date) to learn more about the generator.

Various other pieces of important information are described by the [Hoodoo::ActiveRecord::Dated RDoc]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Dated.html)

> You **must** use the [`new_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Creator/ClassMethods.html#method-i-new_in) method to instantiate models in order to automatically correctly initialise the attributes of a dated model. At present all this does is ensure that the creation and update time of the new record match the inbound request's `dated_from` value, from the `X-Dated-From` header, to allow a resource to be created as if it has existed from some historical point in time rather than "now"; but in future, this mechanism may potentially do considerably more. Habitually using `new_in` future-proofs your code.

##### Example

###### Generate and run migrations

Taking the `Person` example from earlier, we will extend this model to support historical dating. Assuming you have set up the service shell, written the `Person` model and migration from above and migrated (so `bundle install` etc. has all been done), then this:

```sh
bundle exec bin/generators/effective_date.rb people name date_of_birth
bundle exec rake db:migrate
```

...should create and run migrations that provide history support for the `people` table on columns `name` and `date_of_birth` (and automatically, `created_at` and `updated_at`).

###### Tell the model that it's historically dated now

You need to place a `dating_enabled` declaration in your Active Record model stating that dating support is present:

```ruby
class Person < Hoodoo::ActiveRecord::Base
  dating_enabled
  validates :name, :presence => true
end
```

###### Create a new Person

Make sure your service is running again:

```sh
bundle exec rackup
```

...and create a person called "Bob". Here, **just for this example** we use the `X-Resource-UUID` HTTP header so that the UUID you will get if you run this example are the same as in the documentation; normally this wouldn't be specified. The `X-Dated-From` HTTP header is not secured but also only used for special cases -- essentially it overrides the `created_at` date, so that a historically dated resource can seem to have existed from some specified date _in the past_. If omitted, the service's idea of "now" is used when your API call is processed. Again, its use here is **just for this example** so that the creation date is a known constant:

```sh
curl http://localhost:9292/v1/people \
     --data '{"name":"Bob"}' \
     --header "Content-Type: application/json; charset=utf-8" \
     --header "X-Resource-UUID: da9161c8326f4a628e222b3ec1eab3f3" \
     --header "X-Dated-From: 2015-11-30T00:00:00Z"
```

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob"
}
```

###### Change their name

Wait a minute or two, then change Bob's name to `Bob Smith`:

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --request PATCH \
     --data '{"name":"Bob Smith"}' \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob Smith"
}
```

This new version of the Person instance always "exists from" the time of processing in the service, so it appears in the internal history with a date/time from whenever the above example `curl` command gets run.

###### Examine historical versions

We can look at a representation of bob dated at the time the record was first created by providing an `X-Dated-At` HTTP header with an ISO 8601 subset date/time value. If we try to read from a time _before_ the resource existed, it cannot be found.

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "X-Dated-At: 2010-01-01T00:00:00Z" \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T21:17:28Z",
  "errors": [
    {
      "code": "generic.not_found",
      "message": "Resource not found",
      "reference": "da9161c8326f4a628e222b3ec1eab3f3"
    }
  ],
  "id": "d308a52a3c30435e91c979bb069e7db7",
  "interaction_id": "a95f112fedb845f0ad32a8cc3aea0ee5",
  "kind": "Errors"
}
```

> The HTTP header `X-Dated-From` for a `POST` operation gives the date/time _from which_ the historically resource will have appeared to exist; the `X-Dated-At` header for a `GET` operation asks for the representation _as it looked at_ the given date/time.

To read the original "Bob" we can just use the resource's `created_at` time. In this example we specified the precise creation time with an `X-Dated-From` header, so we know exactly when this was. Otherwise though the idea of "now" inside the service will fall on a fractional second and the rounded creation time shown in the representation may have been rounded _down_, so asking for that _precise_ creation time might yield a surprising "not found" result. We simply add one second to the time to be sure!

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "X-Dated-At: 2015-11-30T00:00:01Z" \
     --header "Content-Type: application/json; charset=utf-8"
```

...to get the original "Bob":

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob"
}
```

If we just omit the dated-at time, the resource's most recent (current) representation is returned. This should yield the new name of "Bob Smith".

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "Content-Type: application/json; charset=utf-8"
```

...to get the newer name of "Bob Smith", but still with the same original creation time of course:

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob Smith"
}
```

The most recent version continues to be reported from any point in time between when that most recent version was created and 'now'. Times in the future are prohibited, but beware NTP clock drift between your computer's idea of "the future" and your service's server's idea of "the future". In this example, the year 2078 ought to be far enough forward to be sure of an appropriate error response!

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "X-Dated-At: 2078-11-30T21:14:48Z" \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T21:16:03Z",
  "errors": [
    {
      "code": "generic.malformed",
      "message": "X-Dated-At header value '2500-11-30T21:14:48Z' is invalid",
      "reference": "X-Dated-At"
    }
  ],
  "id": "8c7e4f0d638746e0bf369aaf90a6b289",
  "interaction_id": "df022b973dd049dda97630e58e9059af",
  "kind": "Errors"
}
```

###### Deletion

If you delete the record, then its historical versions can still be retrieved but now, attempts to read it with date both before its `created_at` date/time, or after its deletion date/time, will result in a `generic.not_found` response. First delete the record:

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --request DELETE \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob Smith"
}
```

Then, a minute or two later, try to read it without any time specified (i.e. see its state 'now'):

```sh
curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T21:17:05Z",
  "errors": [
    {
      "code": "generic.not_found",
      "message": "Resource not found",
      "reference": "da9161c8326f4a628e222b3ec1eab3f3"
    }
  ],
  "id": "9b0fcf1126ef4e2e82c21a7f2c995c78",
  "interaction_id": "070b21e440b548f2a71227a97268d9eb",
  "kind": "Errors"
}
```

You can still go "back in time" and look at the original record or any historical variant, given the correct date/time:

curl http://localhost:9292/v1/people/da9161c8326f4a628e222b3ec1eab3f3 \
     --header "X-Dated-At: 2015-11-30T00:00:01Z" \
     --header "Content-Type: application/json; charset=utf-8"
```

```json
{
  "created_at": "2015-11-30T00:00:00Z",
  "id": "da9161c8326f4a628e222b3ec1eab3f3",
  "kind": "Person",
  "name": "Bob"
}
```

#### Translation

> Future enhancement!

In due course, a translation mixin will alleviate the considerable burden of supporting multiple languages within a model in manner which supports the [Hoodoo API Specification's]({{ site.custom.api_specification_url }}) stated internationalisation mechanics. Presently though, this mixin is just a placeholder.



### Writing data

#### Writer

As with the 'reader' extensions described earlier, the 'writer' extensions include recommended patterns for persisting data and will automatically include (where appropriate) writing-related extensions that might be added to Hoodoo in future, if they're mixed in.

See [`Hoodoo::ActiveRecord::Writer`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer.html) and the class methods in [`Hoodoo::ActiveRecord::Writer::ClassMethods`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer/ClassMethods.htm). Include in an `ActiveRecord::Base` subclass manually as follows:

```ruby
class SomeModel < ActiveRecord::Base
  include Hoodoo::ActiveRecord::Writer
  # ...
end
```

...or define your model as a subclass of `Hoodoo::ActiveRecord::Base` to include all available mixins automatically.

##### UUIDs

The UUID of a resource is automatically assigned not by the database, but by the Hoodoo UUID mixin. See the [`Hoodoo::ActiveRecord::UUID` RDoc information]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/UUID.html) for details. You can manually assign values to the `id` column if you wish; your service should support the [`X-Resource-UUID` header]({{ site.custom.api_specification_url }}#http_x_resource_uuid) either implicitly or by explicitly fetching the `"id"` key's value from `context.request.body` and assigning it to a new model instance, as per previous examples and descriptions.

##### Race conditions

The most important part of Writer is the [`persist_in` class method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer/ClassMethods.htm#method-i-persist_in) and accompanying [instance method]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer.html#method-i-persist_in). The bulk of the important RDoc information is given alongside the class method.

As you'll see from reading the RDoc references above, race conditions exist with Active Record when more than one instance of a service supporting a particular resource endpoint is running. Application-level checks for validation, especially uniqueness, happen before database-level checks. Using `persist_in` habitually will guard against various errors and give your service `X-Deja-Vu` support for that particular resource endpoint "for free". See the [Hoodoo API Specification]({{ site.custom.api_specification_url }}) for details.

#### Creator

The [`Hoodoo::ActiveRecord::Creator`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Creator.html) mixin and its [class methods]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Creator/ClassMethods.html) -- in particular [`new_in`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Creator/ClassMethods.html#method-i-new_in) -- provides the preferred way to create instances of models in a way that's context-aware and will be able to pick up any future creation-related mixins without requiring implementation code changes. The `new_in` method in particular is the only way to create instances safely that conform to requirements of the [historical dating support mechanism](#Dating).

#### Error mapping

A Hoodoo mixin is available which maps ActiveRecord validation errors to platform errors as best it can. The [`Hoodoo::ActiveRecord::ErrorMapping`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/ErrorMapping.html) mixin's [`adds_errors_to?` RDoc documentation]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/ErrorMapping.html#method-i-adds_errors_to-3F) has full information about how it works, including a description of how validations for Active Record nested attributes (for associations) are handled.



## Low level

### Thread safety

Usually service applications run single-threaded. Ruby threads don't provide much of a performance improvement. Using multiple application _processes_ to run things in parallel is generally a much more successful strategy. You might see reasonable throughput for database-heavy services if you run a couple of Ruby threads within a single process because MRI does context switch effectively while waiting for I/O but, beyond that, returns diminish rapidly.

The middleware is thread-safe and supports Rack multithreaded mode. The ActiveRecord extensions _are single threaded within a particular model instance_, so don't do something crazy like assigning a specific Active Record model object instance to a class variable and referring to it across many requests! Look up a new instance each time.

If using multiple threads, bear in mind that regardless of Active Record extension safety, _your service implementation's singleton instance will be re-entered_ across many threads. You own code in your service implementation must itself be thread-safe. You can't use instance variables safely, for example, but there should be no need for that kind of construct in a stateless request-based service anyway.

### Active Record connection pool

#### Threading

When Hoodoo is handling a request, the point at which it dispatches the sanitised, high level version of it to your service is wrapped in a call to get a connection from the Active Record connection pool. In pseudocode:

```ruby
def call( env )
  context = process_rack_request( env )

  ActiveRecord::Base.connection_pool.with_connection do
    dispatch_to_service( context )
  end
end
```

At the time of writing the instance method called `dispatch` inside `middleware.rb` contains the core connection wrapper and service dispatch code. Given the above and a single-threaded web server driving Rack, the middleware and your service application, you might expect to only use one connection from the pool -- and this is correct, provided you're not using Event Machine anywhere underneath Rack (see later) and provided that you _don't inter-resource call yourself_. If your service contains more than one resource, then if one of those resources calls another, it'll run back through the middleware _as a local method call_ all within you existing dispatch context. That'll cause a nested call to get another connection from the pool as Hoodoo sends the target request back in to the same service application. You would now need two connections, or a deadlock would occur and Active Record would time out after a few seconds of waiting for a spare connection to become free.

By default the Active Record connection pool holds 5 connections to the database and, given the above, this is typically best left unchanged for single-threaded services. It gives headroom for same-service inter-resource calls or other unexpected extra connection users. If using a multi-threaded server, you'll have to increase the connection pool as a multiple of maximum number of threads -- so for two threads, a connection pool size of 10 is recommended, for three threads use 15 and so-on. To configure the pool size, use the `pool` option in `config/database.yml`, e.g.:

```yaml
default: &default
  adapter: postgresql
  encoding: utf8
  database: service_person_development
  pool:     30
```

You can use ERb inside YAML to parameterise this -- for example:

```erb
default: &default
  adapter: postgresql
  encoding: utf8
  database: service_person_development
  pool:     <%= ( ENV[ 'NUMBER_OF_THREADS' ] || 1 ) * 5 %>
```

A similar situation exists for Rails applications and threaded servers, as explained by a [Heroku Dev Center article](https://devcenter.heroku.com/articles/concurrency-and-database-connections).

#### Event Machine

Event Machine, or similar Node.js-like mechanisms to provide better throughput in a single threaded system via a worker queue that runs during I/O wait states, _do_ effectively cause re-entrant behaviour and use extra connections from the connection pool. If using an AMQP-based queue deployment for your services with Alchemy AMQ then, at the time of writing, this uses Event Machine and must have an `EM_THREADPOOL_SIZE` environment variable setting that supports the inter-resource calling queue mechanism semantics under the hood. You must use a value of at least 3; if you request fewer thread pool entries, an inter-resource call to a remote service application may fail.

The default `EM_THREADPOOL_SIZE` for Event Machine is 20. Configure the database pool size according to the same rules as above -- thread pool size multiplied by a recommended safe value of 5.

```erb
default: &default
  adapter: postgresql
  encoding: utf8
  database: service_person_development
  pool:     <%= ( ENV[ 'EM_THREADPOOL_SIZE' ] || 20 ) * 5 %>
```

### Active Record transactions

Active Record itself uses a transaction around any given normal persistence operation like `save`. Hoodoo's `persist_in` writer mechanism uses a nested transaction to, somewhat surprisingly, work around issues that would otherwise arise from nested transactions and the re-validation done within the `persist_in` system. Details of this are available from the [Hoodoo::ActiveRecord::Writer::ClassMethods]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/ActiveRecord/Writer/ClassMethods.htm) RDoc, in a detailed note about nested transactions.

There is no other unusual transaction behaviour within the Hoodoo Active Record extension code.
