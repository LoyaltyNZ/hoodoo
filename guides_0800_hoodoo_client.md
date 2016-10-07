---
layout: default
categories: [guide]
title: "Hoodoo::Client"
---

## Purpose

Hoodoo includes built in support for _calling_ APIs as a third party consumer. Although the bulk of Hoodoo code is concerned with API provision on the server side, a number of aspects of its behaviour are reusable in an external context. In particular, when one resource implementation needs to talk to another, it does so using a system of resource discovery, endpoint definition and with return value semantics that are also exposed to external callers through `Hoodoo::Client`.

This Guide describes the client interface, explains how the discovery process works and shows how to write new discoverer classes for both client and internal inter-resource use.



## By example

This code sample:

* Defines a client instance which talks to an API endpoint at `api.test.com` and doesn't need Sessions (all actions are public).
* Asks the client for a resource endpoint for version 2 of a `Book` resource API.
* Lists the first 25 Books in category `cooking` sorted by `title` ascending (in this example we'll say that this resource defines a sort key of `title` and a search parameter of `category`).
* Deals with the outcome, be it success or failure.

```ruby
client = Hoodoo::Client.new(
  base_uri:     'https://api.test.com/',
  auto_session: false
)

book_endpoint = client.resource( :Book, 2 )

books = book_endpoint.list(
  offset:    0,
  limit:     25,
  sort:      :title,
  direction: :asc,
  search:    { :category => 'cooking' }
)

if books.platform_errors.has_errors?
  # Examine 'books.platform_errors', which is a
  # Hoodoo::Errors instance, and deal with the contents.
else
  # Treat 'books' as an Array of Book instance Hashes.
end
```

## In detail

### Obtain a `Hoodoo::Client` instance

The `Hoodoo::Client` constructor provides lots of options and is discussed in detail in the [RDoc documentation]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Client.html#method-c-new). It details with the basic overview, discusses how to manage Sessions automatically or manually and describes how discovery of resources at a given endpoint works. Code samples are included.

The references to _discovery_ and _discoverers_ include links to related RDoc data but that's quite low level, so a little hard to fathom at first glance. At the core of it all is the concept of how to find the location on the internet (or local machine) of a given resource when asked for it.

* A "by convention" discoverer uses Rails-like pluralisation rules. For some configured base URI, it will add `/v1/[path]` to it, where `[path]` is the requested resource's name, lower cased and pluralised according to [ActiveSupport pluralisation rules](http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-pluralize). A mechanism for providing exceptions where the pluralisation rules don't give the right results is provided. This can be selected and default-configured by using the Client's `base_uri` constructor parameter.

* A "by DRb" discoverer is usually reserved for local development special cases. When running up local service implementations under test on arbitray HTTP ports, Hoodoo automatically spawns a small background DRb (Distributed Ruby) server which records the resources which that service implements and the port on which they can be found. Several such services could be stood up on different ports. A `Hoodoo::Client` instance using a DRb discoverer would then talk on `localhost` and "know" which ports to use for a given resource based on the information held by the behind-the-scenes Hoodoo DRb server. The Client's `drb_host` or `drb_port` constructor parameters can be used to select and default-configure such a discoverer.

* You can write your own discoverers by creating sub-classes of [`Hoodoo::Services::Discovery`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Discovery.html).

* You can instantiate any out-of-box or entirely custom discoverer and explicitly pass in that specific instance using the Client's `discoverer` constructor parameter, overriding discoverer selection via the optional `base_uri`, `drb_host` and `drb_port` parameters.

### Ask for a resource endpoint

A Client instance is an endpoint factory. You ask the client for objects which represent the endpoints where specific versions of specific resources are located.

### Talk to the resource

#### Common methods

The endpoint instance is addressed using high level methods:

* `list`
* `show`
* `create`
* `update`
* `delete`

These all have some common signature aspects which are discussed in the RDoc material for [`Hoodoo::Client::Endpoint#new`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Client/Endpoint.html#method-c-new). This includes common parameters along with in-page links for the individual methods above.

#### Existential crises

Endpoint contact is lazy. If you ask for an endpoint to a resource which does not exist, an endpoint instance will still be returned. It is only when you try and talk to it that a "not found" error would be returned via the returned result object's `platform_errors` collection.

```ruby
# 'endpoint' will be created and returned:
#
endpoint = client.resource( :DoesNotExist )

# 'result.platform_errors.has_errors?' may be 'true'
# after this line runs:
#
result = endpoint.list()
```

#### Enumerating over resources

The `list` method provides access to a single page within a collection of resources, and it is often useful to retrieve the entire collection. To save callers from having to manually paginate through the resources,  [`Hoodoo::Client::AugmentedArray`]({{site.custom.rdoc_root_url}}/classes/Hoodoo/Client/AugmentedArray.html) provides the [`Hoodoo::Client::PaginatedEnumeration#enumerate_all`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Client/PaginatedEnumeration.html#method-i-enumerate-all) method that will yield each of resources instances to the supplied block individually and perform the pagination automatically.  It is important for the caller to check for errors on each iteration.

> Using `enumerate_all` has the following performance overheads, when compared to paginating manually.  Local inter-resource calls will have each Resource in the collection converted from a `Hash` to a [`Hoodoo::Client::AugmentedHash`]({{site.custom.rdoc_root_url}}/classes/Hoodoo/Client/AugmentedHash.html) in order to provide a consistent interface to callers. The  [`Hoodoo::Client::AugmentedHash`]({{site.custom.rdoc_root_url}}/classes/Hoodoo/Client/AugmentedHash.html) can hold data or errors. In the situation when an error does occurs in the underlying `list` call, then the error is copied into the [`Hoodoo::Client::AugmentedHash`]({{site.custom.rdoc_root_url}}/classes/Hoodoo/Client/AugmentedHash.html) that is yielded to the block.

Example:

```ruby
book_endpoint = client.resource( :Book )

endpoint.list().enumerate_all do | book |
  # Must check for error on each iteration
  if book.platform_errors.has_errors?
    # Deal with error
    break
  end
  # Process book - a Hoodoo::Client::AugmentedHash
end
```

#### Feature discovery

If a resource does not support a particular action, you can still call the endpoint asking for it; the returned result will include an appropriate error. At the time of writing, there is no generic feature discovery mechanism. When you call an endpoint you're expected to know why you're calling it and what it can (or cannot) do. Individual APIs might offer their own strategies for feature detection, or just rely on some kind of API version.



### Custom endpoint discoverers

The interface for the `Hoodoo::Client` constructor includes certain parameters that indicate a specific discovery engine is supposed to be used, as described earlier. The `discoverer` parameter lets you pass in a specially configured discoverer.

#### Out-of-the-box discoverers

We might want to override pluralisation rules for the by-convention discoverer; ActiveSupport pluralises "Health" to "Healths" at the time of writing, for example, but it's unlikely that you would stand up a "Health" resource at a `.../healths` path if you wanted your URIs to look 'sensible'. Suppose we also wanted to specify a custom web proxy, too:

```ruby
discoverer = Hoodoo::Services::Discovery::ByConvention.new(
  :base_uri => 'https://api.test.com/',
  :proxy_uri => 'http://auth:details@proxy.test.com:port',
  :routing  => {
    :Version => { 1 => '/v1/version' },
    :Health  => { 1 => '/v1/health'  }
  }
)

client = Hoodoo::Client.new(
  discoverer: discoverer,
  # ...
)
```

#### Custom discoverers

In theory, you can create your own discoverer by creating a subclass of `Hoodoo::Services::Discovery`, but at the time of writing full integration of custom subclasses into the middleware is not complete. For discovery to work end-to-end, as a service initialises it would need to broadcast information about its IP address and port, or queue name or some other equivalent, to some kind of registry. The custom discoverer would know how to broadcast (announce) to that registry and how to read (discover) from it.

Presently, Hoodoo only knows how to instantiate and announce the presence of a given set of resources when a service "wakes up" according to whether it's configured on a queue (the 'by Consul' discoverer, itself currently a placeholder, is run) or over HTTP directly (the 'by DRb' discoverer is run). See the [Environment Variables Guide]({{ site.baseurl }}/guides_1000_env_vars.html) for information related to one-queue versus not-on-queue behaviour, along with documentation for the middleware's `#on_queue?` method [in RDoc]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#method-c-on_queue-3F).

If your discoverer can determine the location of a resource by version and name alone -- a 'by convention' discoverer, only using different conventions from the convention discoverer provided by Hoodoo -- then you can at least write something along the following lines:

```ruby
class CustomDiscoverer < Hoodoo::Services::Discovery

  # Called by the base class's constructor and passed all options from that
  # constructor. You get to choose whatever options you like, in a Hash;
  # don't override the constructor itself. Some of these options may end up
  # being passed to the 'result' object - see "discover_remote" below.
  #
  def configure_with( options )
    # ...@foo = options[ :foo ]...
  end

  # Without Hoodoo middleware integration this would never be called, but as
  # a placeholder just use the code shown below.
  #
  def announce_remote( resource, version, options = {} )
    return discover_remote( resource, version )
  end

  # This is where you apply your custom convention-based discovery rules
  # and generate a discovery *result* or 'nil'. At the time of writing, the
  # 'ForHTTP' and 'ForAMQP' result options (real HTTP, or HTTP-over-AMQP)
  # are the only available transports.
  #
  def discover_remote( resource, version )
    uri_of_resource = by_convention_generate_uri( resource, version )

    if uri_of_resource.nil?
      return nil
    else
      return Hoodoo::Services::Discovery::ForHTTP.new(
        resource:     resource,
        version:      version,
        endpoint_uri: uri_of_resource
      end
    end
  end

  private

  def by_convention_generate_uri( resource, version )
    # ...
  end
end
```

...then instantiate it with whatever options you require and pass the instance to a Client in its constructor's `discovery` parameter.

#### Further reading

Remember, RDoc has deeper technical information about all of the classes and methods involved:

* [Discovery class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Discovery.html)
* [`configure_with`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Discovery.html#method-i-configure_with)
* [`announce_remote`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Discovery.html#method-i-announce_remote)
* [`discover_remote`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Discovery.html#method-i-discover_remote)
