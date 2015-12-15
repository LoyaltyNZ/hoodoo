---
layout: default
categories: [guide]
title: Testing
---

## Purpose

This guide helps you write test code for your resources, to ensure reliable operation under normal or adverse conditions.



## Principles

### Aim for full test coverage

You should generally aim for 100% non-trivial code coverage. Some traditional unit testing can approach trivial, thus lacking value. It can be somewhat difficult to isolate certain parts of service code anyway. So:

* Your interface class definitions should never, or at worst very rarely contain any code at all beyond Hoodoo declarations so useful test options for those are limited, assuming you trust Hoodoo.

* Implementation classes might only contain the "five action methods" and testing those is better done via integration tests than unit tests; however, `#verify` (the [Security Guide]({{ site.baseurl }}/guides_0200_security.html)) and any custom methods may lend themselves towards unit tests well.

* Implementation class action unit tests would need a mock `context`. There is a risk of ending up with so much mocking that the test has little meaning, even if it has technically equal _coverage_ to an integration test hitting the same action method through a real API call. This can give a false sense of security.

It's up to you whether you choose to put the burden of an implementation's business logic into implementation private methods and try to unit test those via `send`, or into models which you unit test via `spec/models`, or just use comprehensive integration testing to be sure that real-world API callers will get the correct results. RCov can at least tell you if you've hit all the _lines_ of code.

Above all, remember that while an excellent starting point, 100% coverage doesn't mean you've hit all possible combinations of parameters, which often isn't even practical anyway; nor would it help with any multi-instance race conditions or similar that you might encounter in a deployment with more than one instance handling requests. You have to start getting inventive with your test code to catch that kind of thing.

Often, a service's test suite is at least as big as the service itself and may be more technically innovative or complex.

### Integration test approach

Write integration tests using the DSL provided by the integrated [rack-test](#https://github.com/brynary/rack-test) gem to make close-to-real requests to your service without any Hoodoo faking. Examples:

```ruby
# Test #create

post 'v1/resources',
     '{ "foo": "bar" }',
     { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

# Test #list

get '/v1/resources?sort=created_at&direction=asc',
    nil,
    { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

# Test #show

get '/v1/resources/...',
    nil,
    { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

# Test #update

patch '/v1/resources/...',
      '{ "foo": "baz" }',
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

# Test #delete

delete '/v1/resources/...',
       nil,
       { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
```

Note the headers here are in Rack format, so other they're in upper case, use underscores not hyphens and, except for `Content-Type` and 'Content-Length', have an additional `HTTP_` prefix (Rack's a bit strange like that!) so a header such as `X-Session-ID` is given as `HTTP_X_SESSION_ID`.

### RSpec and "let"

Consider this integration test, with lots of setup boilerplate hidden:

```ruby
describe "#list" do
  let( :uri  ) { "/v1/foos" }
  let( :body ) { nil        }

  # ...set up test seed data via FactoryGirl in a 'before' block then...

  context "with a limit" do
    let( :uri ) { "/v1/foos?limit=2" }

    it "returns the correct 'Foo' instances in the correct order" do
      expect(
        parsed_data( get( uri, body, headers ) )[ "_data" ].map{ | h | h[ "name" ] }
      ).to eq( [ "Magic Foo Name 2", "Magic Foo Name 1" ] )
    end
  end
end
```

It doesn't look too bad, but imagine you've got 5 or 10 or 50 of those different list query blocks in there. Any other issues aside, there is a problem arising from the requirement for nested contexts because of `let`; one cannot just assign a value inside an `it` block. Context nesting hell arises. Other issues include:

* Execution order dependencies in `let` can be a hidden trap
* Spec code is less easy to read as there's a confusion of local variables, arbitrary local method calls or `let` variable references

A more defendable example would use `let` to hide away the `parsed_data( get... )` code and this approach is examined below; even so, overuse of `let` in this way can make it hard to follow how a test works. A light touch is needed.

Things look better if we use instance variables for constants.

```ruby
describe "#list" do
  @query = ''

  let( :uri  ) { "/v1/foos?#{ @query }" }
  let( :body ) { nil                    }

  it "returns the correct 'Foo' instances in the correct order" do
    @query = 'limit=2'
    expect(
      parsed_data( get( uri, body, headers ) )[ "_data" ].map{ | h | h[ "name" ] }
    ).to eq( [ "Magic Foo Name 2", "Magic Foo Name 1" ] )
  end
end
```

This removes a nested context and with a syntax highlighting editor, the use of `@query` (or other instance variables) calls out places where you're referring to setup data, not a method or local variable.

Instead of using `let` for per-test constants, perhaps use `let` to DRY up the code. For example:

```ruby
context "#list" do
  @query = ''

  let( :uri  ) { "/v1/foos?#{ @query }" }
  let( :body ) { nil }
  let( :list ) {
    list = parsed_data( get( uri, body, headers ) )
    expect( list[ 'errors' ] ).to be_nil # You'll see the platform errors in RSpec diff output if this test fails
    expect( list ).to have_key( '_data' )
    list[ '_data' ]
  }

  it "returns the correct 'Foo' instances in the correct order" do
    @query = 'limit=2'
    expect( list.map{ |h| h["name"] } ).to eq( [ "Magic Foo Name 2", "Magic Foo Name 1" ] )
  end
end
```

<a name="UsingLet"></a>For the one-off `it` example here this is unnecessary, but it would rapidly win out once the number of tests within the `#list` context increased. Even so, the would-become-repeated `.map` call is tedious and there are hardcoded back-references to setup data everywhere. A further improvement is to create a helper method somewhere that checks lists against expected output. For example:

```ruby
context "#list" do
  @query = ''

  let( :uri  ) { "/v1/foos?#{ @query }" }
  let( :body ) { nil }
  let( :list ) {
    list = parsed_data( get( uri, body, headers ) )

    expect( list[ 'errors' ] ).to be_nil # You'll see the platform errors in RSpec diff output if this test fails
    expect( list ).to have_key( '_data' )

    list[ '_data' ]
  }

  def verify_list( *expecting )
    expect( list.size ).to eq( expecting.size )

    list.each_with_index do | item, index |
      expect( item[ 'id' ] ).to eq( expecting[ index ].id )
    end
  end

  before :each do
    @now = Time.now # I like this approach but Timecop's OK too

    @foo1 = FactoryGirl( :foo, :created_at => @now - 2, :updated_at => @now - 2, ... )
    @foo2 = FactoryGirl( :foo, :created_at => @now - 1, :updated_at => @now - 1, ... )

    # etc, using structured names for @foo so it's obvious which instance
    # they refer to. Set created_at and updated_at as offsets of @now to
    # ensure within-timer-resolution correct by-datetime sort ordering.
  end

  it "returns the correct 'Foo' instances in the correct order" do
    @query = 'limit=2'
    verify_list( @foo2, @foo1 )
  end
end
```

This has the benefit of also implicitly and accurately testing the expected default sort orders in your verification calls and it doesn't require any hard-coded knowledge of seed data set up through FactoryGirl. This is of course now quite a long chunk of code, but thereafter, test after test can boil down to just a single `verify_list` line and/or assignments to `@query`.

Often, though, the "magic code" price to pay for `let` and the restrictions on the context in which it may be used can be too high a price to pay. That's why the [simple example given later](#SimpleExample) doesn't use it but, as with just about anything in your test suite, the details are up to you.



## Mock sessions

Hoodoo has a default test session which is [described by RDoc]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#DEFAULT_TEST_SESSION). This can be overridden easily:

* Record the current test session **before each** test
* Establish the new test session **before each** test
* Restore the recorded old test session **after each** test

You must restore the previous session to avoid polluting subsequent tests with a session established in prior tests. Failing to do this can cause all sorts of confusing failures, especially with random test execution order enabled.

```ruby
before :each do
  @old_test_session = Hoodoo::Services::Middleware.test_session()

  # Build the new session

  @session_id     = Hoodoo::UUID.generate
  @caller_id      = Hoodoo::UUID.generate
  @caller_version = 1
  @session        = Hoodoo::Services::Session.new( {
    :session_id     => @session_id,
    :memcached_host => '0.0.0.0:0',
    :caller_id      => @caller_id,
    :caller_version => @caller_version
  } )

  @session.permissions = Hoodoo::Services::Permissions.new

  # ...then call @session.permissions.set_resource to grant
  # just the *LOCAL* service you're testing with enough
  # permissions.

  Hoodoo::Services::Middleware.set_test_session( @session )
end

after :each do
  Hoodoo::Services::Middleware.set_test_session( @old_test_session )
end
```

A more lightweight approach duplicates the test session and alters just, say, the session ID or some other simple entry. Remember of course that this is a shallow clone, so don't modify any sub-objects inline or you'd be breaking the default test session for everyone:

```ruby
before :each do
  @old_test_session = Hoodoo::Services::Middleware.test_session()

  session_id = Hoodoo::UUID.generate()
  test_session = Hoodoo::Services::Middleware::DEFAULT_TEST_SESSION.dup
  test_session.session_id = session_id

  Hoodoo::Services::Middleware.set_test_session( test_session )
end

after :each do
  Hoodoo::Services::Middleware.set_test_session( @old_test_session )
end
```



## Inter-resource calls

When you want to integration test part of a resource implementation which makes one or more inter-resource calls as part of its operation, you may want to, or may have to mock those calls for test.

### Local inter-resource calls

When you make an inter-resource call to a resource that you know is implemented in the _same_ service application, then either let the actual implementation get called and run normally for a full integration test, or mock the endpoint for something closer to a unit test of the specific resource implementation under test.

RSpec can do this with the usual tools -- for example:

```ruby
expect_any_instance_of( SomeLocalResourceImplementation ).to receive( :create )...
```

Usually you'll have no choice but to `expect_any_instance_of` an implementation class to receive one of the five primary action methods, even though RSpec's documentation recommends that this method be avoided where possible, because you have no way of knowing what actual instance was created by the middleware when the test suite started to run.



### Remote inter-resource calls


If you make inter-resource calls from one service application _to a different_ service application, you will need to somehow mock that _external_ resource endpoint in tests. The code below shows a way up a mock remote service containing the required resource endpoint(s) so your tests can be self-contained and simulate a variety of unusual return types / errors / etc. from the remote endpoint in question.

This is a useful approach as you can easily mock expected, correct data as well as error conditions or edge condition responses from the remote resource and make sure that your calling service still behaves correctly.

```ruby
# Suppose I have a service which makes an *external*/remote
# inter-resource call to a resource called "Clock".
#
# Using stuff in Hoodoo's spec_helper.rb, here's how to define
# a mock Clock resource endpoint, stand it up in its own HTTP
# service and allow calls to it.

describe SomeLocalServiceClass do

  # Absolute bare minimum set of classes to define a Clock -
  # make sure the ClockInterface defines the correct resource
  # name, endpoint and version.
  #
  class ClockImplementation < Hoodoo::Services::Implementation
  end

  class ClockInterface < Hoodoo::Services::Interface
    interface :Clock do
      endpoint :clocks, ClockImplementation
    end
  end

  class ClockService < Hoodoo::Services::Service
    comprised_of ClockInterface
  end

  # As shown in the 'Mock sessions' section, it's likely to
  # be useful to define a bespoke test session. By using a
  # very restricted permission set, you will be testing that
  # any inter-resource calls have requested appropriate
  # additional permissions in the interface (or not, if that
  # is your design decisions). Under the default test session
  # permission is granted for any action on any resource, so
  # inter-resource calls would never be prohibited because of
  # a failure to declare the requirements in an interface.
  #
  before :each do
    @session_id     = Hoodoo::UUID.generate
    @caller_id      = Hoodoo::UUID.generate
    @caller_version = 1
    @session        = Hoodoo::Services::Session.new( {
      :session_id     => @session_id,
      :memcached_host => '0.0.0.0:0',
      :caller_id      => @caller_id,
      :caller_version => @caller_version
    } )

    @session.permissions = Hoodoo::Services::Permissions.new

    # ...then call @session.permissions.set_resource to grant
    # just the *LOCAL* service you're testing with enough
    # permissions. No permissions for Clock!
    #
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    Hoodoo::Services::Middleware.set_test_session( @session )
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  # Here's where we spin up ClockService inside its own
  # thread under WEBRick. The method called here returns the
  # port number that the service is listening on, but we don't
  # care; the middleware's DRb service will register this new
  # endpoint and thus, when your code-under-test tries to
  # make a remote inter-resource call, the middleware will
  # find the thing you've run here.
  #
  # To be clear: This runs up the *MOCK REMOTE TARGET* thing
  # that you're NOT testing directly.
  #
  before :all do
    spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockService )
  end

  context 'inter-resource calls to Clock endpoint' do

    # Define your under-test implementation class as the thing
    # that we'll call using the RSpec DSL locally.
    #
    # To be clear: This "runs up" the *LOCAL SERVICE UNDER TEST*
    # that will make an inter-resource call to the mock remove
    # service started earlier.
    #
    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run SomeLocalServiceClass.new
      end
    end

    # The "and_return" block must be a formally correct resource,
    # so perhaps do that by factories and/or the Hoodoo presenters
    # to render yourself some canonical expected 'on success' case
    # for Clock.
    #
    # You'd need to do more advanced things with a block if you
    # wanted to actually get the 'context' object and add errors
    # to it, to simulate the Clock endpoint failing and make sure
    # your calling service then handled that failure case.
    #
    it 'does stuff that requires it to call Clock#show and handles success' do
      expect_any_instance_of( ClockImplementation ).to receive( :show ).and_return( {} )

      get '/v1/resource_you_are_testing', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      expect( last_response.status ).to eq( 200 )
      result = JSON.parse( last_response.body )
      # ...etc...
    end
  end
end
```



## Mock contexts

Whenever an action method like `show` or `create` is called under test, a `context` parameter is passed that describes the full request. If you're using the RSpec DSL for integration tests, methods like `get` or `post` work through the stack and call into your implementation's action method via Hoodoo, so there's no more work to do. Should you wish to directly call into your action methods for any reason though, you will need a minimal mock request context to pass as the method's argument.

At the time of writing, a minimal useful constructor for such a thing looks like this:

```ruby
before :each do
  # Get a good-enough-for-test interaction which has a context
  # that contains a Session we can modify.

  @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
  @interaction.context = Hoodoo::Services::Context.new(
    Hoodoo::Services::Session.new,
    @interaction.context.request,
    @interaction.context.response,
    @interaction
  )

  @context = @interaction.context
  @session = @interaction.context.session
end
```

The 'at the time of writing' caveat exists because at this point you're mocking things that are part of the Hoodoo internal implementation. There's a potential for that to break in some way, even with the interface to the service not changing. Hoodoo might extend the context object with some new property that must be set for the middleware to function properly, even if its presence is optional for the called service.

Looking inside the Hoodoo test suite is a good way to proceed if you have trouble. The above code sample was originally taken from [`secure_spec.rb`](https://github.com/LoyaltyNZ/hoodoo/blob/f8ff047/spec/active/active_record/secure_spec.rb#L68) though the [most recent version of the file](https://github.com/LoyaltyNZ/hoodoo/blob/master/spec/active/active_record/secure_spec.rb) may by now be different. For a more complex / complete example, see the tests for the Context object itself in [`context_spec.rb`](https://github.com/LoyaltyNZ/hoodoo/blob/f8ff047/spec/services/services/context_spec.rb#L18). This even builds a mock middleware instance based on a mock service application class. Again, be sure to check the [most recent version of the file](https://github.com/LoyaltyNZ/hoodoo/blob/master/spec/services/services/context_spec.rb) for differences.



## <a name="SimpleExample"></a>Simple example

You may well want to follow a test-driven development workflow and create tests before you write code that implements the under-test behaviour. Here, however, useful prior example code exists to which we can add tests retrospectively. We will use the `service_person` example from the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html). Source code is available in [this archive]({{ site.baseurl }}/examples/service_person.zip).

The coverage demonstrates a few simple full integration tests and just gives some ideas for how you might choose to implement more complete test coverage in your own services.

### Preparation

Before you can run any tests, you need to create the test database:

```sh
RACK_ENV=test bundle exec rake db:create db:migrate
```

### Boilerplate

Create file `spec/service/integration/person_integration_spec.rb` and add the basic test boilerplate:

```ruby
require 'spec_helper'

RSpec.describe 'Person integration' do
end
```

### Create

#### Factories

For demonstration purposes we'll use the built-in [Factory Girl](https://github.com/thoughtbot/factory_girl) and [Faker](https://github.com/stympy/faker) support to create factories for People models with names, or names and dates of birth.

Create file `spec/factories/person.rb` and add in the factory code:

```ruby
FactoryGirl.define do
  factory :person do
    name { Faker::Name.name }

    factory :person_with_dob do
      date_of_birth { Faker::Date.between( 80.years.ago, 10.years.ago ) }
    end
  end
end
```

Now we can do things like `FactoryGirl.create( :person )` to create and save into the database a randomly named Person instance without a date of birth specified, or `FactoryGirl.create( :person, :name => 'Frank' )` to override the random name with "Frank".

#### Tests

Back in `person_integration_spec.rb` we will add a context to test the `create` method, along with a helper method. Here, the helper method hides away a lot of cut-and-paste code that might arise from all the calls made to perform `POST` requests. Instead of a helper method, you could use one or more referential `let` blocks as shown in some earlier examples. Explicit methods can be easier to follow though and helper methods can more easily be extracted out into an arbitrary Ruby files and `require`'d as necessary for reuse, without being impeded by rules about being inside `describe` or `context` blocks at parse time.

```ruby
  context '#create' do

    # Makes a POST call to create a Person resource and, if an expected
    # HTTP status code is seen, returns the parsed result (else fails the
    # expectation).
    #
    # +body_hash+::     Hash to convert to JSON and send in the POST request.
    # +expected_code+:: Optional expected HTTP response code as an Integer or
    #                   String. If omitted, defaults to 200.
    #
    def do_create( body_hash, expected_code = 200 )
      response = post(
        '/v1/people',
        JSON.generate( body_hash ),
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( response.status.to_s ).to(
        eq( expected_code.to_s ),
        "Expected status code '#{ expected_code }', got '#{ response.status }' with body: #{ response.body }"
      )

      return JSON.parse( response.body )
    end

    # ...

  end
```

> Note the Rack-friendly specification of the `Content-Type` header; a header such as `X-Session-ID` would be specified as `HTTP_X_SESSION_ID`.

Now we can replace the "# ..." with a few real tests. They should be quite terse since a lot of the basic work is already being done by `do_create`.

```ruby
    it 'persists' do
      expect {
        do_create( 'name' => 'Harry' )
      }.to change { Person.count }.by( 1 )
    end

    it 'renders correctly' do
      result = do_create( 'name' => 'Harry' )

      expect( result[ 'kind' ] ).to eq( 'Person' )
      expect( result[ 'name' ] ).to eq( 'Harry'  )
    end

    it 'refuses creation without a name' do
      result = do_create( {}, 422 )

      expect( result[ 'errors' ].count ).to eq( 1 )
      expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'generic.required_field_missing' )
      expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'name'                           )
    end

    it 'refuses creation with a bad date of birth' do
      result = do_create( { 'name' => 'Jane', 'date_of_birth' => 'bad date' }, 422 )

      expect( result[ 'errors' ].count ).to eq( 1 )
      expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'generic.invalid_date' )
      expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'date_of_birth'        )
    end
```

#### Running the tests

Run the entire suite with e.g.:

```sh
bundle exec rspec
```

If you want to see each test printed line by line instead of the "dots", add a formatting argument to the command:

```sh
bundle exec rspec -f d
```

You can run folders full of tests by specifying the folder name -- e.g. just to run the service tests and leave out the generator tests (assuming you didn't just delete those from the service shell starting point):

```sh
bundle exec rspec spec/service
```

You can also specify individual filenames and lines within files for specific tests. See the `bundle exec rspec --help` or the [online RSpec documentation](http://rspec.info) for details.

#### There's more to do

There is clearly more coverage that could be done here, but this covers many of the `curl` examples that were given in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) examples. If you wanted to be sure that input validation was working, then trying to POST with unknown field names or attempt SQL injection might be valuable. You may wish to split the expectations up into finer grained tests, or combine them to reduce duplication. You may wish to ensure that `X-Resource-UUID` works when an up-front ID is given, by extending the `do_create` helper and checking the database for the expected UUID after a successful API call. It's all up to you.

### Show

This is where Factory Girl comes in. We will create a couple of Person instances then try to find just one. To be extra-paranoid, the Factory Girl creation code will make sure that the two Person instances have different names, so that when we try to look one of them up, we can double-check that the API returned the correct one and be sure of no accidental test passes.

```ruby
  context '#show' do
    before :each do
      @p1 = FactoryGirl.create( :person_with_dob )

      begin
        @p2 = FactoryGirl.create( :person_with_dob )
      end while @p1.name == @p2.name
    end

    # Makes a GET call to retrieve a Person resource and, if an expected
    # HTTP status code is seen, returns the parsed result (else fails the
    # expectation).
    #
    # +uuid+::          UUID to find.
    # +expected_code+:: Optional expected HTTP response code as an Integer or
    #                   String. If omitted, defaults to 200.
    #
    def do_show( uuid, expected_code = 200 )
      response = get(
        "/v1/people/#{ uuid }",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( response.status.to_s ).to(
        eq( expected_code.to_s ),
        "Expected status code '#{ expected_code }', got '#{ response.status }' with body: #{ response.body }"
      )

      return JSON.parse( response.body )
    end

    it 'finds a person' do
      result = do_show( @p2.id )

      expect( result[ 'name'          ] ).to eq( @p2.name                  )
      expect( result[ 'date_of_birth' ] ).to eq( @p2.date_of_birth.iso8601 )
    end

    it '404s with a not-found UUID' do
      new_uuid = Hoodoo::UUID.generate()
      result   = do_show( new_uuid, 404 )

      expect( result[ 'errors' ].count ).to eq( 1 )
      expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'generic.not_found' )
      expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( new_uuid            )
    end
  end
```

### List

This is probably the most interesting set of tests and coming up with an efficient pattern for testing combinations of searches, filters, limits and orders will help you a lot with efficient testing of resources as you develop them and add more search/filter strings, sort orders, or entirely new resources to your collection.

If you choose to use Factory Girl to create a few model instances in the database before tests run, as here, then watch out for created/updated times. The code might run so quickly that within your database's timer resolution, they appear to be created at the same instant; creation-time based sorting may not work reliably. There are lots of solutions to this but most of them revolve around specifying the creation and updating times manually.

```ruby
  context '#list' do
    before :each do
      time   = Time.now - 10.minutes
      create = Proc.new do | attrs |
        time = time + 1.minute
        FactoryGirl.create( :person, attrs.merge( :created_at => time, :updated_at => time ) )
      end

      @p1 = create.call( :name => 'Alice One', :date_of_birth => '1975-03-01' )
      @p2 = create.call( :name => 'Alice Two', :date_of_birth => '1984-09-04' )
      @p3 = create.call( :name => 'Bob One',   :date_of_birth => '1975-11-23' )
      @p4 = create.call( :name => 'Bob Two',   :date_of_birth => '1956-02-01' )
    end

    # ...

  end
```

As with other examples, a `do_something` method (here, `do_list`) makes the actual API call and an additional helper method checks lists of resources against lists of model instances. This makes it easy to specify the expected lists, in order, in terms of the instance variables assigned in the above code and compare that to API response data. Replace `# ...` above with:

```ruby
    # Makes a GET call to retrieve a list of Person resources and, if an
    # expected HTTP status code is seen, returns the parsed result (else
    # fails the expectation).
    #
    # +search+::        Optional search Hash; if omitted, defaults to empty.
    # +expected_code+:: Optional expected HTTP response code as an Integer or
    #                   String. If omitted, defaults to 200.
    #
    # The search Hash can use either String or Symbol keys or values.
    #
    def do_list( search = {}, expected_code = 200 )
      query = ''

      unless search.empty?
        encoded_search = URI.encode_www_form( search )
        query = '?' << URI.encode_www_form( 'search' => encoded_search )
      end

      response = get(
        "/v1/people#{ query }",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( response.status.to_s ).to(
        eq( expected_code.to_s ),
        "Expected status code '#{ expected_code }', got '#{ response.status }' with body: #{ response.body }"
      )

      return JSON.parse( response.body )
    end

    # Compare a list of Person models with an API list call response holding
    # a list of Person resource representations, expecting each to match.
    #
    # +resources+:: The result from an API list call, complete with '_data'
    #               top-level key.
    # +models+::    A list of Person model instances, in the expected order.
    #
    def compare_lists( resources, *models )
      models.each_with_index do | model, index |
        resource = resources[ '_data' ][ index ]

        expect( model.name                  ).to eq( resource[ 'name'          ] )
        expect( model.date_of_birth.iso8601 ).to eq( resource[ 'date_of_birth' ] )
      end
    end

    # ...
```

We always have one API call response but want to compare it against a changing list of model instances. By specifying the API call response first and using the `*models` approach for an arbitrary length list of parameters afterwards, the calls to `compare_list` become quite clean as shown in the tests below. That said, if you prefer to use a `let`-based approach as shown earlier, [the `verify_list` example method](#UsingLet) provides an even more terse interface.

In any case, here we add tests to check all the search combinations that were given as examples in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html). Replace `# ...` above with:

```ruby
    it 'lists all' do
      result = do_list()
      compare_lists( result, @p4, @p3, @p2, @p1 )
    end

    it 'finds "alices"' do
      result = do_list( :partial_name => 'alice' )
      compare_lists( result, @p2, @p1 )
    end

    it 'finds names containing "E"' do
      result = do_list( :partial_name => 'E' )
      compare_lists( result, @p3, @p2, @p1 )
    end

    it 'finds people born in 1975' do
      result = do_list( :birth_year => '1975' )
      compare_lists( result, @p3, @p1 )
    end

    it 'finds "alices" born in 1975' do
      result = do_list( :partial_name => 'alice', :birth_year => '1975' )
      compare_lists( result, @p1 )
    end
```

### Coverage and logs

When all of the above is running, execute the full suite with:

```sh
bundle exec rspec
```

At the end of the test, a summary report is printed to the console and there's a mention of a "coverage report" in `...coverage/rcov`. Open file `coverage/rcov/index.html` in a web browser (on Mac OS X, this can be done from the command line with `open coverage/rcov/index.html`) to see the report. Full coverage doesn't necessarily mean that all possible code paths are covered of course, but less than full coverage is a clear indicator of missing tests.

Remember that tests run in a random order by default and sometimes coverage gaps can open unexpectedly when orders change, because of accidental dependency coupling between tests. The random seed number is printed for every test run, so if one behaves strangely, re-run the tests in that same order using the `--seed` argument -- `bundle exec rspec --seed <n>` -- and try to find out what's going on. Debugging the test suite will ensure your coverage remains good and the chance of false passes or occasional random failures are minimised.

Finally, don't forget about `log/test.log`. This can be really useful for tracking down crash faults. Often a test expectation might check for a non-500 HTTP status code and this expectation fails if a 500 response arises, but all RSpec would show is the unexpected 500; it wouldn't necessarily print the full JSON response including Ruby backtrace. Although you might choose to write expectation helper methods to solve this, they might make your tests more abstract/obtuse; debugging via the log file may be a better option. Remove any existing log file (it might have grown very large from previous test runs), re-run just the one problematic test and `cat` the log to see the backtrace from the Hoodoo automatic logging output.
