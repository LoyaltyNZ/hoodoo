---
layout: default
categories: [guide]
title: Security
---

## Purpose

Security should be your first concern whenever you write some kind of service. This guide describes the layers of security offered by Hoodoo and the [Hoodoo API Specification]({{ site.custom.api_specification_url }}).



## Rack

Since Hoodoo runs on top of [Rack](https://rack.github.io), various levels of malformed inbound request protection are already provided. Read about Rack to find out more.



## Hoodoo middleware

Rack passes requests to Hoodoo middleware. In Rack's terminology Hoodoo is actually a Rack application since it sits at the end of the request chain, but since Hoodoo itself cannot do anything without a service application to call, it acts as just another piece of middleware within the wider stack.

Before passing a request to a service, Hoodoo does a lot of checking and validation. It is quite strict about what it will accept in order to reduce the chances of successful fuzzing attacks. Hoodoo will reject requests if:

* The `Content-Type` header does not match `application/json; charset=utf-8`
* The HTTP verb and URI path characteristics mismatch
* No resource endpoint is registered at the given URI path
* The resource exists but the HTTP verb in use is not supported by that resource
* The resource exists but the requested action is private and no valid session can be found (see [Sessions, later](#Sessions)) or the service dynamically prohibits the action (see [Dynamic rejection, later](#Dynamic_rejection))
* An attempt is made to use a [secured HTTP header](#Secure_headers) under a [Session](#Sessions) that lacks the ability to use it
* An internal hard-coded maximum payload size is exceeded (see [RDoc for  `Hoodoo::Services::Middleware::MAXIMUM_PAYLOAD_SIZE`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#MAXIMUM_PAYLOAD_SIZE)
* Body data for `POST` or `PATCH` operations does not parse as valid JSON
* Body data for `POST` or `PATCH` operations does not pass [input validation](#Payload_validation), if the resource interface requests such.



## <a name="Sessions"></a>Sessions

Although resources can declare that one or more of their supported actions are public, the default is that all actions are private and Hoodoo will not let you contact that endpoint without a valid Session.

### The Session and its associated Caller

The [Hoodoo API Specification]({{ site.custom.api_specification_url }}) goes into detail about a Session resource and the associated underlying Caller. In brief, the Caller is a resource that describes access credentials for the API and is typically stored indefinitely in a database. The Session is a transient piece of information which is created by passing in the appropriate correct access credentials and refers back to the Caller.

In a `RACK_ENV` mode of `development` or `test`, Hoodoo uses an internal test session. Otherwise, it expects to look them up in [Memcached](http://memcached.org). You must set environment variable `MEMCACHED_HOST` for your service to run successfully (e.g. `MEMCACHED_HOST=127.0.0.1:11211 RACK_ENV=production bundle exec rackup`). If you are using OS X, we recommend the use of [Homebrew](http://brew.sh) and `brew install memcached`; alternatively you might choose to set up a more advanced containerised infrastructure with [Docker](https://www.docker.com) on any platform, but that is well beyond the scope of this Guide.

### Anatomy

Sessions conceptually consist of three parts.

#### <a name="Identity"></a>Identity

This section describes _who you are_, as a caller. The meaning of this is defined by the person designing the API. For example, you might model real world retail companies using a Retailer and an Outlet, assigning Callers to each Outlet. The identity section of a Session could, **through your implementation of the Session endpoint**, contain the IDs of the associated Retailer and Outlet. The implementation of a secure resource endpoint can then easily find out which Retailer and Outlet made the call.

#### Permissions

This session describes _what you can do_ at a resource level. It is a Hash which maps resource names like "Product" to a set of actions. For the given resource and action, these say that access is always allowed, must be verified by asking the target resource's implementation for permission, or is always denied. In the absence of specific "allow" or "ask" entries for a given resource and action, the default is to deny access to a resource and action.

##### <a name="Dynamic_rejection"></a>Dynamic rejection

Permissions are described in RDoc under [`Hoodoo::Services::Permissions`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Permissions.html). Actions have `DENY` or `ALLOW` permissions which are self-explanatory. There is also the value `ASK`; this one asks the service implementation at run-time if the action should be allowed. Hoodoo calls the resource implementation's [`verify` method, described fully in the RDoc documentation]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Implementation.html#method-i-verify). This is a sixth, optional implementation method in addition to the five action methods of `create`, `show` and so-on.

#### Scoping

This section describes _what you can see_, along with supplementary permissions such as [secured HTTP headers](#Secure_headers). Again the entries are up to the implementation of the Session endpoint, but it might, for example, include a list of the IDs of Retailers (using the earlier example) that the session user can see. Suppose we recorded at the persistence layer, from the identity section of a session, which Retailer and/or Outlet caused various resource instances to be created. We might then use this persistence layer information to filter queries on that information, only matching records with a corresponding entry in the session's scoping section. As a result, a session might only be able to "see" the things created by a Retailer which matched its identity; or from some group/coalition of Retailers; or there could be a superuser-like entity which can "see" all things created by all Retailers.

##### With Active Record

Hoodoo provides optional extensions to support users of Active Record. These include a security mechanism. Declarations made inside an Active Record model can connect values of fields in the scoping section of the current caller's session to values of attributes in the model.

In the previous example, one can ask Hoodoo to connect a field in the session's scoping section which contains the permitted Retailer IDs that the session can "see", to a related Active Record model's attribute that stores the ID of the Retailer which created that entry. The net result is that the caller can only see the things they are permitted to see, without any significant coding effort on behalf of the service author and with minimal opportunities for accidentally showing a caller data which should have been hidden -- SQL queries run via such a model can automatically include something along the lines of `retailer_id IN (a,b,c...)`.

For more, see [data model security section, below](#DataModelSecurity).

##### <a name="Secure_headers"></a>Secure headers

Some HTTP headers are only permitted if the scoping section includes an `authorised_http_headers` property. The value is an Array containing the HTTP headers permitted. At the time of writing, these secure headers are defined:

* [`X-Resource-UUID`]({{ site.custom.api_specification_url }}#http_x_resource_uuid): Used in relation to persisted data and explored more in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html).

* [`X-Assume-Identity-Of`]({{ site.custom.api_specification_url }}#http_x_assume_identity_of): Used in rare cases where an API caller wants to temporarily assume a different identity in the [identity section (see above)](#Identity) of the Session. The Hoodoo documentation describes it in depth.

Always check the [Hoodoo API Specification]({{ site.custom.api_specification_url }}) for the up to date, definitive list of secure headers.

#### Sessions during development

When you bring up a service in development mode or in tests, Hoodoo by default uses a default test session that is highly permissive, including allowing full access to all resources and all secured HTTP headers. For details, see [the RDoc documentation]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#DEFAULT_TEST_SESSION). For information about overriding this session, please see the [Testing Guide]({{ site.baseurl }}/guides_0900_testing.html).



## Resource interfaces

When resources describe themselves via their [`Hoodoo::Services::Interface`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html) subclass, various security-related statements can be made.

### Secure logging

Normally Hoodoo fully logs inbound requests and outbound responses. If you've an interface which accepts security credentials (e.g. creating a session), the full inbound log is most likely a bad idea. Likewise, if an interface returns sensitive information, the full outbound log is a bad idea.

Use the [`secure_log_for`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-secure_log_for) method if you want to set security options for one or more actions.

### Public actions

Normally any resource action requires a valid session to operate, but you might have fully public interfaces available -- e.g. some kind of system health-check resource endpoint.

Use the [`public_actions`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-public_actions) method to declare such actions.

### <a name="Payload_validation"></a>Payload validation

Although your resource implementation can choose to validate all inbound JSON payload data for `POST` (create) or `PATCH` (update) actions itself, Hoodoo includes its own validator.

Use the [`to_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_create), [`to_update`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_update) and/or [`update_same_as_create`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-update_same_as_create) methods if you want to describe the payloads and have Hoodoo perform some validation for you. If Hoodoo's built-in validation options aren't sufficient, you can describe as much as the DSL allows then add additional validation in the service, but at least Hoodoo will have done _some_ of the work so you don't have to.

### Inter-resource calls

When a client calls an API endpoint, their Caller must allow access to the resource being targeted. If, as part of its implementation, this resource makes a call to one or more other resources, you have two choices as an API designer:

* Know this up-front and require that the Caller also has permission to perform the relevant additional resource operations.
* Treat this as an internal implementation and hide the permissions from Callers by declaring the additional permissions inside the interface class.

The second option is the preferred, most secure approach. It is catered for by the [`additional_permissions_for`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-additional_permissions_for) method. Using this method, you list out _exactly_ which additional permissions one resource requires according to the actions it is expected to perform in other resources. If it attempts to do anything else, a permissions error would occur and the overall request will fail.

Since you aren't exposing implementation-detail permissions to your Callers, they can only access the bare minimum subset of resources and any additional operations those resources might perform are not "leaked". Should a resource somehow be broken (e.g. by a bad code merge) or compromised and attempt to perform other unexpected inter-resource actions, those actions would be refused. The list of external resource dependencies also gets in effect documented in code in one single place, via the interface declarations; this can be helpful for maintenance and understanding.



## <a name="DataModelSecurity"></a>Data model security

Quite a lot of an API's security will depend upon its resources' underlying data model and the domain-specific restrictions you choose to place on access to that data, above and beyond any restrictions on access to the front-end resources themselves. The Active Record extensions provide quite a lot of support for various filtering approaches and this is all described in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html). If you're going to use Active Record and wish to take advantage of the data model security features, be sure to read that guide in full.
