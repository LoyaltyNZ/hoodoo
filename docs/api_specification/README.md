# Hoodoo API Specification

_Release 2, 2016-01-14_

[](TOCS)
* [Overview](#ao)
* [API call basics](#apicb)
  * [Generalised representation](#apicbgr)
  * [Resources](#apicbr)
    * [Data storage](#apicbrds)
    * [Management](#apicbrm)
    * [All-responses representation](#apicbrarr)
    * [Error handling](#apicbreh)
      * [Platform level errors](#error.common.codes.platform)
      * [Generic API call level errors](#error.common.codes.generic)
      * [Specific resource errors](#error.common.codes.specific)
    * [Common fields and `null` fields](#cf)
    * [Listing, pagination, searches and filters](#lppsf)
    * [Embedding](#apicbre)
      * [Examples](#apicbree)
    * [Internationalisation](#apicbri)
      * [Default language](#apicbridl)
      * [Client to platform](#apicbrictp)
      * [Platform to client](#apicbriptc)
      * [Scoping](#apicbris)
    * [Special HTTP headers](#special_http_headers)
      * [`X-Dated-At`](#http_x_dated_at)
      * [`X-Dated-From`](#http_x_dated_from)
      * [`X-Deja-Vu`](#http_x_deja_vu)
      * [`X-Resource-UUID`](#http_x_resource_uuid)
      * [`X-Assume-Identity-Of`](#http_x_assume_identity_of)
  * [Security](#security)
    * [Access security](#access_security)
      * [Scoping and resource representation](#scoping_and_resource_representation)
    * [Data presentation security](#data_presentation_security)
  * [CORS support](#cors)
* [Authentication API](#authentication.api)
  * [Data Types](#authentication.api.types)
    * [Permissions `::type::permissions`](#permissions.type)
    * [PermissionsResources `::type::permissions_resources`](#permissions_resources.type)
    * [PermissionsDefaults `::type::permissions_defaults`](#permissions_defaults.type)
    * [PermissionsFull `::type::permissions_full`](#permissions_full.type)
  * [Resources](#authentication.api.resources)
    * [Caller `::resource::caller`](#caller.resource)
      * [Interface](#caller.resource.interface)
        * [Identity maps](#caller.resource.interface.identity_maps)
    * [Session `::resource::session`](#session.resource)
      * [Interface](#session.resource.interface)
* [Analytical API](#analytical.api)
  * [Persistence](#analytical.api.persistence)
    * [Information for API callers](#analytical.api.persistence.information_for_callers)
    * [Information for API providers](#analytical.api.persistence.information_for_providers)
  * [Data Types](#analytical.api.types)
    * [ErrorPrimitive `::type::error_primitive`](#error_primitive.type)
  * [Resources](#analytical.api.resources)
    * [Errors `::resource::errors`](#errors.resource)
      * [Interface](#errors.resource.interface)
* [Change history](#change_history)
[](TOCE)

## <a name="ao"></a>Overview

The **Hoodoo API Specification** describes access to one or more **resources** with common interaction semantics, which together provide some kind of coherent API. The system running the collection of resources presenting this API is referred to as **the platform**. External software entities that call the API are referred to as **clients**.

* **Resources**: The platform has a [resource-oriented architecture](http://wikipedia.org/wiki/Resource-oriented_architecture). Interaction with the API involves viewing, creating, updating or destroying resources in the platform.

* **Security**: Clients acquire a session identifier through the [Authentication API](#authentication.api) by creating a [Session resource instance](#session.resource) which is a string representing an access authorisation issued to the client. This MUST be given in all future calls via the HTTP `X-Session-ID` [header](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html) except for calls to public interfaces, such as when POSTing to the [Session](#session.resource) resource itself. **If sessions are used, then when a collection of Hoodoo resources is stood up as a platform, the operator MUST only allow HTTPS or an equivalent secure transport for calls into that platform.** Without this, session identifiers will be visible "on the wire" and no real security will exist at all.

* **Events:** The platform also has an [Event-driven architecture](http://wikipedia.org/wiki/Event-driven_architecture) as a method to drive and decouple resource state changes (or attempted changes). On occasion, a client interacting with a resource will require some kind of notification to an event (completion/failure/rejection) to further drive their interaction. This situation will be handled by the client providing a *secure* callback URL or being provided an internal resource to poll, according to the documentation accompanying a particular resource for which events may be required.

* **UUIDs:** Universally Unique Identifiers are unique (for all time across all resources) strings which are used to identify individual resources. All resource representations are assigned UUIDs by Hoodoo.

* **Logging:** Hoodoo automatically logs all interactions with a resource and includes a unique value for each and every API call via the HTTP `X-InteractionID` header sent in API call responses.

* **Versioning:** All endpoint URIs are scoped by `vX` where `X` is the major version of the API you are calling. For example, an endpoint documented as `/things` would be available at a path of `/v1/things` for major version 1 of the API. This version prefix is implicit to all paths and not explicitly listed in endpoint paths shown elsewhere in this document.

The Hoodoo API Specification assumes that any provider of an assembly of resources in a platform will provide comprehensive documentation for those resource endpoints - otherwise, nobody will know how to use them! From time to time, then, the Hoodoo API Specification may refer to things that ought to be included in such resource documentation; technical authors take note.



## <a name="apicb"></a>API call basics

Since all API calls use the [HTTPS](http://wikipedia.org/wiki/HTTP_Secure) transport, a basic understanding of the [HTTP protocol](http://www.w3.org/Protocols/rfc2616/rfc2616.html) is assumed. Clients MUST support this.

[HTTP status codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html) are used to indicate success (20x), redirection (30x), or failure (4xx, 5xx) of attempts to make calls. In most cases, extra body data will give more information about success or failure conditions, unless there is a platform fault so severe that only a status code response is possible. API clients MUST drive their primary state machine from the response code.

Apart from HTTP to HTTPS redirection described earlier, it is possible that any API call may receive a 30x response. A **301** status code indicates that the called API endpoint has permanently moved; for best efficiency, clients MAY note the new location and not call the old location again. A **307** response indicates that the called API endpoint has temporarily moved. The caller must support such redirections, by retrying the same API operation with the same HTTP method and same parameters, but at the new endpoint location specified in the 30x response via the HTTP `Location` header.

* 20x - success
* 3xx - handle HTTP redirection per HTTP spec
* 401, 403 - try and get a new session, then retry
* 408 - retry later
* 5xx - inform the API / platform operator and be prepared to retry
* All others - probable caller error; examine and fix calling code if necessary



### <a name="apicbgr"></a>Generalised representation

* **All client API calls MUST include the `Content-Type: application/json; charset=utf-8` HTTP header and value.**

* Absolutely all strings/text that are sent to the platform MUST, or are returned by the platform WILL, be encoded in [UTF-8](http://tools.ietf.org/html/rfc3629).

* Representation of all "things" expressed through API call request bodies and response bodies is done with [JSON encoding](http://wikipedia.org/wiki/JSON).

* All times/dates WILL be converted to, stored and reported in UTC+0 regardless of the time zone in which they were specified, using the [W3 XML schema datetime type](http://www.w3.org/TR/xmlschema-2/#dateTime) **with timezone**, which is a restricted subset of the [ISO 8601](http://wikipedia.org/wiki/ISO_8601) format. Dates/times originating from within the platform itself will be stored and reported in UTC+0.

Issues such as timezone-relevant time and date display for user interfaces, localised number formatting and so forth are a matter for the client and not the domain of the API or platform.



### <a name="apicbr"></a>Resources

The API bases itself on the architectural constraints of [REST](http://wikipedia.org/wiki/Representational_state_transfer), so is stateless, cacheable and so forth. Resources are identifiable units of functionality that often model a real world concept, though may be more abstract. Examples could include a resource representing a shopping basket as part of an e-commerce system or an abstract "Addition resource", used for mathematical calculations.

Most resources are described in terms of key/value pairs, where values may be references to other resources. Some are also described in terms of data Types. A Type is a set of reusable, logically grouped properties. An API may describe a library of Types which can be both used by clients in API calls to make requests, or are expressed as representations of results in API responses. The Hoodoo API Specification includes some Types itself.

While the parameters used to _create_ a resource will often be similar to the returned _representation_ of the created resource, they may be entirely different. Consider the Addition resource - we might 'create' this by providing a list of integers, but when we ask for the representation of that Addition, it might just be the sum of those integers. Often a resource can be created with a minimum of information, with missing data obtained from resource specific defaults; the representation of the resource might have everything, including those defaults. This is part of the Hoodoo API Specification's general future proofing strategy.

#### <a name="apicbrds"></a>Data storage

Clients MUST NOT make assumptions about the persisted nature of data stored when resources are created, beyond that it is persistent and, unless otherwise documented, stored indefinitely.

#### <a name="apicbrm"></a>Management

The baseline API for management of a given resource is [CRUD](http://wikipedia.org/wiki/Create,_read,_update_and_delete), meaning there are operations to create, read (show/list), update (modify) and delete resource(s). Not all resources may support all of those operations. The relationship between RESTful design and CRUD is expressed through the HTTP method used to perform an action:

* `GET` to a resource endpoint to read one or list many
* `POST` to an endpoint to create something
* `PATCH` to an endpoint to modify something (in part or in full)
* `DELETE` to an endpoint to delete something

#### <a name="apicbrarr"></a>All-responses representation

To reduce the number of required API calls, the platform endeavours to keep clients informed about the condition of a resource on all calls.

* When a resource is created, the success response body provides a representation of that resource just as if you had used a `GET` call to retrieve it.

* When a resource is updated, the success response body provides a representation of the updated resource.

* When a resource is deleted, the success response body provides a representation of the deleted resource, in the state it was in just prior to deletion. This facilities stack-like call behaviour; clients MUST remain aware that the resource no longer exists and its UUID is (forever) invalid.

Some calls may deviate from this route for reasons of relevance or performance. If so, the exception must be clearly documented. Use of the [`X-Deja-Vu`](#http_x_deja_vu) HTTP header may result in HTTP 204 response codes without any response body. In any other case, assume the above behaviour.

#### <a name="apicbreh"></a>Error handling

When 4xx or 5xx HTTP status codes are returned, clients may wish to check for a response body that will contain a JSON structure giving more information about the error, if it were possible to generate one (severe system errors may prohibit this). The **[Errors resource](#errors.resource)** is the returned structure.

Inside an [Errors resource instance](#errors.resource) are one or more [ErrorPrimitive Type](#error_primitive.type) entries, which include associated error codes, reference data and human-readable messages. Although some resources specify their own custom errors, certain error conditions can arise across any resource. Error codes for such conditions are delivered under specific HTTP response codes with meaning as described in the following sections.

##### <a name="error.common.codes.platform"></a>Platform level errors

Platform-level errors generally arise from the top level of API call processing, above the service layer.

| HTTP response code        | `code`                             | `reference`     | Meaning |
|---------------------------|------------------------------------|-----------------|---------|
| 404 Not Found             | `platform.not_found`               | "{entity_name}" | No valid interface endpoint was found for the requested path (`reference` will be an empty string); your API call was not processed further at all by the platform. |
| 422 Unprocessable Entity  | `platform.malformed`               | Undefined       | URL path, query string or request body data was malformed, or contained unexpected data. Associated message and arbitrary reference data _may_ provide more information for developers to examine. |
| 401 Unauthorized          | `platform.invalid_session`         | Undefined       | The `X-Session-ID` header value has been omitted, or does not contain a valid session identifier ("we don't know who you are"). |
| 403 Forbidden             | `platform.forbidden`               | Undefined       | The `X-Session-ID` header value refers to a valid session, but the session data prohibits the attempted action, special HTTP header usage or other top-level behaviour ("we know who you are, but you can't do that"). |
| 405 Method Not Allowed    | `platform.method_not_allowed`      | Undefined       | Attempt to use an HTTP method in a call to an interface which does not support it ("we know who you are and you're allowed to try that, but the target resource doesn't support it"). |
| 408 Request Timeout       | `platform.timeout`                 | Undefined       | Internal systems did not respond within a given timeout period. Retry the request later. |
| 500 Internal Server Error | `platform.fault`                   | "{exception}"   | An internal platform error occurred. If exception information is available it will be put in the `reference` data in string form, else `reference` will be an empty string. |

When a `408 Request Timeout` is received, the general recommendation is, after a back-off delay, to retry the operation, setting the [`X-Deja-Vu`](#http_x_deja_vu) HTTP header for creation or deletion attempts. See that header's documentation for details.

##### <a name="error.common.codes.generic"></a>Generic API call level errors

Resource-level errors generally arise if a problem is detected during request processing in the Hoodoo service layer.

| HTTP response code       | `code`                             | `reference`    | Meaning |
|--------------------------|------------------------------------|----------------|---------|
| 404 Not Found            | `generic.not_found`                | "{ident}"      | The resource described by the UUID given in the `reference` field was not found; relevant for API calls that take UUIDs in URLs. |
| 422 Unprocessable Entity | `generic.malformed`                | Undefined      | A payload was malformed and could not be parsed. |
| 422 Unprocessable Entity | `generic.required_field_missing`   | "{field_name}" | The field at `reference` is required and is empty or not supplied. |
| 422 Unprocessable Entity | `generic.invalid_string`           | "{field_name}" | The field at `reference` is not a valid string. |
| 422 Unprocessable Entity | `generic.invalid_integer`          | "{field_name}" | The field at `reference` is not a valid integer. |
| 422 Unprocessable Entity | `generic.invalid_float`            | "{field_name}" | The field at `reference` is not a valid JSON floating point number. |
| 422 Unprocessable Entity | `generic.invalid_decimal`          | "{field_name}" | The field at `reference` is not a valid JSON floating point number expressed as a string. |
| 422 Unprocessable Entity | `generic.invalid_boolean`          | "{field_name}" | The field at `reference` is not a valid boolean. |
| 422 Unprocessable Entity | `generic.invalid_enum`             | "{field_name}" | The field at `reference` is not a valid enumeration - either its value is not a string, or is not one of the permitted enumeration values. |
| 422 Unprocessable Entity | `generic.invalid_date`             | "{field_name}" | The field at `reference` is not a valid [ISO 8601 subset date](http://www.w3.org/TR/xmlschema-2/#dateTime) date. |
| 422 Unprocessable Entity | `generic.invalid_time`             | "{field_name}" | The field at `reference` is not a valid [ISO 8601 subset time](http://www.w3.org/TR/xmlschema-2/#dateTime) time. |
| 422 Unprocessable Entity | `generic.invalid_datetime`         | "{field_name}" | The field at `reference` is not a valid [ISO 8601 subset date-time](http://www.w3.org/TR/xmlschema-2/#dateTime) date-time. |
| 422 Unprocessable Entity | `generic.invalid_uuid`             | "{field_name}" | The field at `reference` does not look like a valid platform UUID, or should refer to another existing resource but the requested related resource instance cannot be found (for POST/PATCH operations). |
| 422 Unprocessable Entity | `generic.invalid_array`            | "{field_name}" | The field at `reference` should refer to a JSON array, but seems to refer to something else. |
| 422 Unprocessable Entity | `generic.invalid_object`           | "{field_name}" | The field at `reference` should refer to a JSON object, but seems to refer to something else. |
| 422 Unprocessable Entity | `generic.invalid_hash`             | "{field_name}" | The field at `reference` should refer to a JSON object matching a certain key/value Hash-like pattern, but seems to refer to something else or has incorrect keys or values. |
| 422 Unprocessable Entity | `generic.invalid_duplication`      | "{field_name}" | The field at `reference` contains a duplicate value and duplicates are not allowed in the call context. |
| 422 Unprocessable Entity | `generic.invalid_state`            | "{destination_state}" | A resource with a `state` field cannot change from its current state to the one requested in `reference`. |
| 422 Unprocessable Entity | `generic.invalid_parameters`       | Undefined      | Failing all more specific cases, parameters were invalid in some other way; more information is not available, though the `message` string *might* be of assistance. |
| 422 Unprocessable Entity | `generic.mutually_exclusive`       | "{field_names}"      | The fields listed at `reference` are mutually exclusive. |

Remember that error responses to API callers are described as a *collection* of these data types. This can be most apparent when there are inbound data validation failures across multiple fields in the request, resulting in multiple entries in the collection.

##### <a name="error.common.codes.specific"></a>Specific resource errors

Whenever a resource has aspects of its interface that require custom error codes, descriptions of these codes should be given in the documentation for that resource. If in doubt, contact the resource API provider / platform operator.

#### <a name="cf"></a>Common fields and `null` fields

All resource representations contain the following common fields.

| Field        | Meaning |
|--------------|---------|
| `id`         | The UUID of this resource (as a String; a "black box") |
| `kind`       | The resource's name as a string; e.g. "Purchase", "Member" |
| `created_at` | The ISO 8601 subset UTC date/time of creation (as a String; e.g. "2014-06-05T03:34:16Z") |

Some resource representations also contain one or many of the following additional common fields.

| Field          | Meaning |
|----------------|---------|
| `language`     | For resources with content subject to internationalisation only; see the [internationalisation](#apicbri) section for details |
| `secured_with` | For resources that intentionally reveal security scoping information; see the [access security](#access_security) section for details |

All of these values are _emergent_ - they are generated via Hoodoo as part of creating a resource instance. **Clients do _not_ specify these values as input!**

For any other fields which clients _do_ provide, then if you explicitly pass `null` for the value of a field when creating a new, or updating an existing resource instance, that `null` value is used. This is a way to clear values for optional fields and/or override defaults if you wish. Where fields have mandatory non-null values, attempting to do this will of course provoke an error.

In returned rendered representations of resources, the system may choose to present optional "unset"/empty fields as explicitly present with a `null` value, or it may choose to omit those optional fields in the representation.

The [Errors resource](#errors.resource) may in rare circumstances not have an `id` field present, in which case the resource representation has _not_ been persisted. This can occur for very severe errors where persistence was impossible or if the error generator considers persistence unwise - for example, if it might be possible for an unauthorised caller to easily provoke the error and use it as a vector for a denial of service attack on the database.

#### <a name="lppsf"></a>Listing, pagination, searches and filters

In the case of HTTP `GET` requests, individual resource representations are fetched by providing the instance's UUID. Lists of resources (the "index view") can also be obtained, with pagination, sorting and sometimes searching (things to include) or filtering (things to exclude) requested through a standardised approach. For all lists, [URI query strings](http://wikipedia.org/wiki/Query_string) are used to specify list parameters. Given "x=y" key/value pairs in the query string:

| Key         | Allowed values and meaning |
|-------------|----------------------------|
| `offset`    | Positive integer saying how far into the list you want to start (page offset). Default: `0`. |
| `limit`     | Positive non-zero integer saying how many items you want to be returned. Default: `50`. |
| `sort`      | Different resources support different sort keys, but all of them support `created_at` - the date-time of resource creation. Default: `created_at`. |
| `direction` | `asc` for ascending order, `desc` for descending order (may be language-dependent); some resources may support more values. Default: `desc`. |
| `search`    | A resource-specific search string, which exposes simple search (inclusion) features, documented per-resource. Default: No search. |
| `filter`    | A resource-specific filter string, which exposes simple filter (exclusion) features, documented per-resource. Default: No filter. |

* Remember to properly [escape reserved characters, plus spaces](http://wikipedia.org/wiki/Percent-encoding) in the query string.

* All resources support the default sort key and direction at a minimum (unless otherwise stated), but may provide documented additional capabilities.

* Multiple sort orders can be specified using comma-separated names, such extra supported sort key names being documented by individual resources where available. When using multiple sort keys, a sort direction MUST be given for each of the sort keys, in order; for example: `...&sort=last_name,first_name&direction=asc,desc` - that is, the sort key and direction lists must match in length.

* Multiple sort keys and directions can alternatively be provided using separate query string entries. They are read in order of appearance. The following are all equivalent:

  * `...&sort=last_name,first_name&direction=asc,desc`
  * `...&sort=last_name&sort=first_name&direction=asc&direction=desc`
  * `...&sort=last_name&direction=asc&sort=first_name&direction=desc`

  Use whichever form your prevailing code environment lends itself to most naturally.

* Search and filter strings describe **one query string value**, so you **must [URL / query string escape](http://wikipedia.org/wiki/Percent-encoding) all characters inside them**, including "`=`" as `%3D`. Within that value, search and filter strings are simple and of the form `key=value`, where the meaning of the key and the way in which the value matches something is documented per-resource. Searches include results where there's a match, filters exclude results where there's a match. The procedure is:

  * Percent-escape the individual _keys and values_ making up the search or filter string
  * Assemble those together with "=" between key and value and "&" between key/value pairs, just as if it were a normal URL query string
  * Percent-escape that entire entity for inclusion in the wider query string
  * This quite intentionally results in double-escaping for the individual keys and values.

  At the receiving service end, the query string is unescaped and split into its key/value pairs, then search and filter values are treated as nested escaped key/value strings which are unescaped and split again.

  For (contrived) example, to list some resource from offset 75 in a page size of 25 sorting by hypothetical field `name` ascending, searching for `name` values of string literal `str?ange=value` (!) and hypothetical awkwardly named field `address,street` value of `11 Cable Street`, the escaped values to search for become `str%3Fange%3Dvalue` and `11%20Cable%20Street`, so assembling the search string and percent-encoding the whole thing gives, in total:

  `offset=75&limit=25&sort=name&direction=asc&search=name%3Dstr%253Fange%253Dvalue%26address%252Cstreet%3D11%2520Cable%2520Street`

  ...or annotating those single and double escape sequences for clarity:

  `offset=75&limit=25&sort=name&direction=asc&search=name` `%3D` `str` `%253F` `ange` `%253D` `value` `%26` `address` `%252C` `street` `%3D` `11` `%2520` `Cable` `%2520` `Street`

  ...so that the implementation can easily split out all the query string key/value pairs, leaving a `search` value of:

  * `name%3Dstr%253Fange%253Dvalue%26address%252Cstreet%3D11%2520Cable%2520Street`
  * `name` `%3D` `str` `%253F` `ange` `%253D` `value` `%26` `address` `%252C` `street` `%3D` `11` `%2520` `Cable` `%2520` `Street`

  ...which unescapes to:

  * `name=str%3Fange%3Dvalue&address%2Cstreet=11%20Cable%20Street`
  * `name` `=` `str` `%3F` `ange` `%3D` `value` `&` `address` `%2C` `street` `=` `11` `%20` `Cable` `%20` `Street`

  ...yielding the nested key/value pairs to be split and unescaped by the search mechanism.

* As with sort keys and directions, search and filter data can also be provided as a collection of separate query string entries too - so for example, `...&search=name%3Dfoo&search=address%3Dbar` or `...&search=name%3Dfoo%26address%3Dbar` are equivalent.

* Duplicated sort keys, search keys and filter keys will provoke undefined behaviour. Usually, the last duplicated entry to appear in the query string will be the one that takes precedence, but this is not guaranteed and MUST NOT be relied upon. Callers SHOULD NOT send in duplicated keys.

* Since standard JSON cannot represent arrays at the top level of a response, an object is returned containing property `_data`, where the property's value is the array of results.

  ```javascript
  {
    "_data": [
      {::resource::*},
      // ...
    ]
  }
  ```

* Lists MAY (but will not always) contain a full count of the number of records available across the entire selected set of resources through a `_dataset_size` property. For example, regardless of pagination (`offset` / `limit`), if a given query identified 331 resource instances, then the returned data _may_ include the size as follows:

  ```javascript
  {
    "_data": [
      {::resource::*},
      // ...
    ],
    "_dataset_size": 331
  }
  ```

  The count is accurate at the instant the call is processed by the system.

* Lists MAY (but will not always) contain a rough count of the number of records available across the entire selected set of resources through an `_estimated_dataset_size` property. For example, regardless of pagination (`offset` / `limit`), if a given query identified roughly 141,419,500 resource instances, then the returned data _may_ include the size as follows:

  ```javascript
  {
    "_data": [
      {::resource::*},
      // ...
    ],
    "_estimated_dataset_size": 141419500
  }
  ```

  The estimation is made at the instant the call is processed by the system. Use of an estimation rather than an accurate count is a choice made by the implementation of a particular resource endpoint and is usually employed for performance reasons. This is especially likely to be used if the resource in practice is comparatively "high volume" and is likely to become associated with very large number of entries in a persistent storage layer.

  No guarantees can be given about accuracy at the Hoodoo level. If an API client needs the count in order to produce, say, a page-based GUI that shows lists of resource instances, a page count derived from the dataset size estimation will of course itself be an estimation. An implementation would need to handle the cases that:

  * The actual dataset size is slightly or much smaller than estimated: Any number of pages at the end of the estimated page range might be empty.

  * The actual dataset size is slightly or much greater than estimated: The last page in the estimated range may be full, so an option to fetch even more pages needs to be made visible to the user.

  This is a decision that can only be made at run-time as paged lists are fetched.

#### <a name="apicbre"></a>Embedding

Any given resource supports a list of zero or more things that can be embedded within its representation, *in an API call response*. This avoids the need for either multiple API calls ("get me the details of a user", "get the details of the user account", "get the user's account balance") or hard-wired "combinatorial" / "variation" API calls ("get me the details of a user, including account number and account balance" vs "get me the details of the user and account in full" etc.).

When you show, list, create, update or delete a resource, you can ask for its returned representation to include extra embedded data via the URI query string. Individual resources support different embedding keys, so these should be documented for each resource. By default, a resource supports no embedded items.

For example, imagine creating a record of some kind of purchase by a `POST` to a hypothetical Purchase resource endpoint. The payload of the client's API call would contain information on what was purchased and, in addition, the API call might request that the returned representation of the purchase embeds information on any Vouchers that the purchaser gained as a result of their purchase. Provided that the Purchase resource documents that it can contain embedded Vouchers, this is possible.

* For _any HTTP method,_ the syntax to embed a full (sub-)resource representation is to use a query string entry of `_embed={resource-name[,resource-name,...]}` - that is, a comma-separated list of whatever names of embeddable things the resource in question lists as supported. In the above example, the `POST` URI might include `&_embed=vouchers,balance` to return the purchaser's updated vouchers and loyalty currency balance (if that platform's API supports such concepts).

* Embedded data is included in the JSON response under a top-level key called `_embed`. The leading underscore is used as a simple namespace to avoid collision with the resource's own property names. This leading underscore is echoed in the underscore within the query string for consistency.

* Depending upon your requirements and use case, you can embed either full resources or just UUIDs for a lighter weight call. To just return UUIDs, use a query string of `_reference={resource-name[,resource-name,...]}`.

* The returned embedded reference(s) is/are included in the JSON response under a top-level key called `_reference`.

* For a `GET` that retrieves a list of resources, embedding applies to each item returned in the list, so you get a collection of representations of instances of the same shallow "graph" of data each time. It is not possible to customise the embedded resources on a per-item basis within a list. A client must make API calls for each individual resource instance of interest to achieve this level of control.

* In the case of _embedded lists_ within any given resource instance - in the above example, `vouchers` is a list of Voucher resource representations embedded within the Purchase representation - then the embedded resource's **default pagination order and page size is enforced and only the first page is embedded**. There is no way to modify this. If you need more control, you will have to make an additional API call to the embedded resource's endpoint and ask for a customised list.

* Resource documentation should list the supported embeddable things and the names to use to request them, stating whether or you get a list of things, or just one thing embedded.

##### <a name="apicbree"></a>Examples

Suppose that a Member can acquire various Vouchers through their purchasing activity. We want the details of a Member and a list of the most recent Vouchers they have earned. An API call is made to get the Member details, embedding the Voucher information:

* References only - `GET https://api.test.com/v1/members/<member_uuid>?_reference=vouchers` results in:

  ```javascript
  {
    "id": "6010AF3FE3F94F56A6B98A3D27C1CAEF",
    "created_at": "2012-02-01T00:00:00Z",
    "informal_name": "Tom",
    "_reference": {
      "vouchers": [
        "33CCE8C9DEF8470DAC1A87215C434EE0",
        "CCBC1D8B25EF4EAD8DD3C3CB24324B1E"
      ]
    }
  }
  ```

  ...i.e. there is a JSON key `_reference` containing an object with its own keys, corresponding to each name of a reference that was requested in the URI query string. For lists of references, this is simply an array of UUID strings.

* Full embed - `GET https://api.test.com/v1/members/<member_uuid>?_embed=vouchers` results in:

  ```javascript
  {
    "id": "6010AF3FE3F94F56A6B98A3D27C1CAEF",
    "created_at": "2012-02-01T00:00:00Z",
    "informal_name": "Tom",
    "_embed": {
      "vouchers": [
        { "id": "33CCE8C9DEF8470DAC1A87215C434EE0", "created_at": "2014-12-12T00:00:00Z", ... },
        { "id": "CCBC1D8B25EF4EAD8DD3C3CB24324B1E", "created_at": "2014-12-12T00:00:00Z", ... }
      ]
    }
  }
  ```

  ...i.e. there is a JSON key `_embed` containing an array of representations of the embedded resource in full, in the default sort order for that resource.

Suppose now we wanted to get both Voucher list information *and* information on a single Account associated with the hypothetical Member.

* References only - `GET https://api.test.com/v1/members/<member_uuid>?_reference=vouchers,account` results in:

  ```javascript
  {
    "id": "6010AF3FE3F94F56A6B98A3D27C1CAEF",
    "created_at": "2012-02-01T00:00:00Z",
    "informal_name": "Tom",
    "_reference": {
      "vouchers": [
        "33CCE8C9DEF8470DAC1A87215C434EE0",
        "CCBC1D8B25EF4EAD8DD3C3CB24324B1E"
      ],
      "account": "5B930F1604324018A73D71502CE9C53B"
    }
  }
  ```

  ...note the additional `account` entry. Since this is just one reference, not a list, it's just the UUID string rather than an array of strings.

* Full embed - `GET https://api.test.com/v1/members/<member_uuid>?_embed=vouchers,account` results in:

  ```javascript
  {
    "id": "6010AF3FE3F94F56A6B98A3D27C1CAEF",
    "informal_name": "Tom",
    "_embed": {
      "vouchers": [
        { "id": "33CCE8C9DEF8470DAC1A87215C434EE0", "created_at": "2014-12-12T00:00:00Z", ... },
        { "id": "CCBC1D8B25EF4EAD8DD3C3CB24324B1E", "created_at": "2014-12-12T00:00:00Z", ... }
      ],
      "account": { "id": "5B930F1604324018A73D71502CE9C53B", ... }
    }
  ```

  ...in a manner similar to the previous example, the embedded `account` key has a value that's the direct representation of the embedded single resource, with no need to wrap it in an outer UUID-keyed object.

Full embedding and references can be mixed freely.

* Mixture - `GET https://api.test.com/v1/members/<member_uuid>?_embed=vouchers&_reference=account` results in:

  ```javascript
  {
    "id": "6010AF3FE3F94F56A6B98A3D27C1CAEF",
    "informal_name": "Tom",
    "_embed": {
      "vouchers": [
        "33CCE8C9DEF8470DAC1A87215C434EE0": { "id": "33CCE8C9DEF8470DAC1A87215C434EE0", "created_at": "2014-12-12T00:00:00Z", ... },
        "CCBC1D8B25EF4EAD8DD3C3CB24324B1E": { "id": "CCBC1D8B25EF4EAD8DD3C3CB24324B1E", "created_at": "2014-12-12T00:00:00Z", ... }
      ]
    },
    "_reference": {
      "account": "5B930F1604324018A73D71502CE9C53B"
    }
  }
  ```

#### <a name="apicbri"></a>Internationalisation

_This section is under review and subject to change._

While UTF-8 encoding of data allows representation of numerous character sets, clients still need to describe the language they are using when sending human-readable data to the platform, or the language they want when retrieving such data from the platform.

##### <a name="apicbridl"></a>Default language

At the time of writing, the platform has a default language of `en-nz`. In a future iteration, this may be configurable.

##### <a name="apicbrictp"></a>Client to platform

* When _sending_ internationalised data to the platform, a client uses the [`Content-Language` HTTP header](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.12) to specify the language of that content. In the first platform release, only a single language is supported, such as in `Content-Language: en-us`. If this header is absent, the [default](#apicbridl) is assumed.

* When _retrieving_ data from the platform, a client uses the [`Accept-Language` HTTP header](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4) to specify the language required. In the first platform release, only a single language is supported, such as in `Content-Language: en-us`. If this header is absent, [default](#apicbridl) is assumed.

* UUIDs for resource instances refer to the same resource instance in however many languages have been defined for it. That is, the same one resource instance can contain internationalised data in different languages, allowing updates of instances with new translations if/when they become available.

##### <a name="apicbriptc"></a>Platform to client

* When sending data to a client as part of an API call response, the platform uses the [`Content-Language` HTTP header](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.12) to specify the actual language of the content. In the first platform release, only a single language is ever returned, as in `Content-Language: en-us`. The header WILL be present in all 2xx status code responses but MAY be absent for redirections or error cases.

* There are no partial language responses. If a resource is requested in a particular language, either all the internationalised fields can be resolved in the language or the default language will be returned. This includes the case where resources are embedded in a request and in the case of lists of resources.

* When sending data to a client as part of an event, strings which are subject to internationalisation will never be included. Instead, references to resources will be included where necessary so that a client can, if need be, make API calls to read the data and specify the language when so doing.

##### <a name="apicbris"></a>Scoping

Some resources have mandatory fields that can be internationalised. Mandatory field constraints must always be satisfied for (at least) the [default language](#apicbridl). This ensures that if a different language is requested but not available, the default language can be used.

#### <a name="special_http_headers"></a>Special HTTP headers

There are a few special-case additional HTTP headers which can be used to modify behaviour.

##### <a name="http_x_dated_at"></a>`X-Dated-At`

* Relevant for HTTP `GET` only
* Value is a date-time of the format described in the ["Generalised representation"](#apicbgr) section
* Requests the system state at the given date-time

The `X-Dated-At` HTTP header is only relevant for HTTP `GET` operations which retrieve resource representations individually or in lists.

Some resource instances can change over time via `PATCH` or `DELETE` operations. For some of these resource kinds, it is possible to _retrieve_ historical representations of resource instances; in effect, to see their change history. Note that _creation_ of resources which might have an ability to specify some kind of backdating/historical information just involves `POST`-ing the required JSON data; for example, a resource might provide a `backdated_to` field indicating some significant historical date is to be associated with the new resource instance. If however an API client wishes to _read_ the historical state of a supporting _mutable_ resource for any reason though, then the HTTP header is used.

If the header is given when reading back the state of a resource which does not support historical representation, the system will simply return the "current" known representation of that resource - the header value is ignored. Resources which _do_ support the header must explicitly state so in their documented interface descriptions.

Note that specifying date/times in the future _according to the platform's clock_ (set via [NTP](#https://en.wikipedia.org/wiki/Network_Time_Protocol) or a similar mechanism) is _not permitted_. As a result, you MUST NOT use this header unless you have a significant difference between the current time and the historical date of interest. Otherwise, network latency coupled with clock drift between your clock and the platform's clock could lead to intermittent errors. As a general rule of thumb:

* Make sure your calling computer's time is also synchronised via a mechanism like NTP
* Do not set an X-Dated-At header within 30 minutes of your concept of "now".

See also [`X-Dated-From`](#http_x_dated_from).

##### <a name="http_x_dated_from"></a>`X-Dated-From`

* Relevant for HTTP `POST` only
* Value is a date-time of the format described in the ["Generalised representation"](#apicbgr) section
* Requests a resource be created as if it started to exist at a historical date-time

The `X-Dated-From` HTTP header is only relevant for HTTP `POST` operations which create resource instances.

This feature is only supported by resources that also support the [`X-Dated-At`](#http_x_dated_at) header. Such resources can be updated, so they may change over time but allow historical versions of their representations to be returned. If an attempt is made to read a resource representation at a date-time from before it was created, the system will return a "not found" response. With the `X-Dated-From` header, you can modify this creation date from the default, which is the instantaneous server date-time of 'now' at the point the resource instance is persisted, to a date-time of your choosing.

Note the subtle difference between this header and things like e.g. a `backdated_to` field in a resource. The former is only for resources that support historical representation, while the latter is for immutable resources that don't require historical representation but _do_ depend upon other resources that change over time.

If the header is given when creating a resource which does not support historical representation, the system will simply create a "at-processing-time" representation of that resource - the header value is ignored. Resources which _do_ support the header must explicitly state so in their documented interface descriptions.

As with `X-Dated-At,` specifying date/times in the future is _not permitted_ so you must follow the same [usage guidelines](#http_x_dated_at).

##### <a name="http_x_deja_vu"></a>`X-Deja-Vu`

* Relevant for HTTP `POST` and `DELETE` only
* Only allowed value is `yes`; header must be omitted for implicit 'no'
* Indicates to the system that the caller might have tried this operation before, but isn't sure

When making API calls, you might encounter an error such as a timeout. In that case, it isn't clear exactly where in the processing chain that the timeout occurred. For example:

* It might be a network problem and your request never reached the platform.
* The request might have reached the platform but then been abandoned during processing.
* The request might have reached been processed fully, but in such a way that a higher level timeout mechanism triggered before it finished.

For `POST` calls, this means a resource instance _might_ have been created. Some resources have no side effects or uniqueness constraints on creation, in which case creating another instance is harmless, if arguably somewhat wasteful. For those resources which have side effects or uniqueness constraints on fields, attempting to create an instance twice could have bad consequences; further, use of the [`X-Resource-UUID`](#http_x_resource_uuid) header, if permitted, means that primary key duplication violations are possible for any resource.

A platform's documented resource collection should ensure that any resource with side effects always includes a field with a uniqueness constraint, such as `caller_reference`, as a first line of defence. Even if use of these is often optional, it is _very highly recommended_ that you always use this facility when presented, because the only problem then remaining is detection of "expected" duplication constraint violations from retries.

To solve this, whenever you might run the same call more than once, set the `X-Deja-Vu` HTTP header with a value of `yes`. A couple of example use cases are:

1. Retry due to timeout.
2. You are making calls from a worker in a queue processing engine which says its workers might run _at least_ once (most of them do).

When the header is used, Hoodoo will no longer treat a uniqueness constraint violation as an error case, but instead of the usual on-success HTTP 200 response code and a returned resource representation in the response body, you will get an HTTP 204 response, an `X-Deja-Vu` HTTP header in the response with a value of `confirmed` and _no body text_. This tells you that the resource seems to already exist; the system "confirms the sense of déjà vu".

Where practical, avoid the use of this header for definite first-time calls and only specify it for might-be-repeat calls. Using it all the time hides issues of genuinely errant attempts to create resource instances with duplication violations on otherwise unique fields.

For `DELETE` calls, the header plays a similar role. A resource instance might already have been deleted. You can avoid special case error handling code and Hoodoo take care of it; client processing code just expects any 2xx series HTTP response code and treats it as an indication of success.

**Note:** If you specify an _invalid_ UUID in a déjà vu deletion, the system has no way to distinguish a UUID of something that used to exist but was deleted from a UUID of something that never existed in the first place. It would return an HTTP 204 status code in either case.

##### <a name="http_x_resource_uuid"></a>`X-Resource-UUID`

* Relevant for HTTP `POST` only
* Restricted
* Value is a [Version 4 UUID with hyphens removed](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_.28random.29)
* Sets a resource instance UUID

This is a _restricted header_, which means only [Sessions](#session.resource) associated with a [Caller](#caller.resource) that has the header name included in its `authorised_http_headers` list will be able to use it.

When present, the `X-Resource-UUID` HTTP header is only relevant for HTTP `POST` operations to create new resource instances. The header's value must be a [valid Version 4 UUID with hyphens removed](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_.28random.29) - i.e. a 32-character hex string. This will be used as the new UUID for that resource instance and reported back as the value of the `id` field in the returned resource representation, if creation is successful.

Callers entrusted with the ability to specify UUID values up front bear responsibility for making sure their generation algorithm is of high quality, especially in regard to entropy and **MUST NEVER** reuse UUID values for obvious reasons!

##### <a name="http_x_assume_identity_of"></a>`X-Assume-Identity-Of`

* Relevant for any call
* Restricted
* **SECURITY SENSITIVE**
* Value is a URL-encoded set of key/value pairs
* Allows session identity override

This is a _restricted header_, which means only [Sessions](#session.resource) associated with a [Caller](#caller.resource) that has the header name included in its `authorised_http_headers` list will be able to use it.

When present, the `X-Assume-Identity-Of` header allows the caller to specify keys and values that will be set in the active [Session's](#session.resource) `identity` section. For that one API call, the caller assumes the identity of someone else.

Normally, identity information is automatic and pulled in from the [Caller](#caller.resource) instance used to create the Session in question. All API calls under a given Session will therefore always contain the same immutable identity information. Under very special cases however, you might want one single caller to be able in essence masquerade as other identities when performing API operations, either for data visibility when reading, or data 'ownership' (scoping) when writing resource information. Although it is generally _strongly encouraged_ that individual Caller instances with their own Session are used for any given identity that you want to use, permitting this secured HTTP header via a privileged Caller definiton will allow you to act as many entities, all within one session.

The system first loads the session data for an incoming API call, then if the secured HTTP header is present, permitted and well-formed, merges the key/value pairs from the header's value into the existing session data. The API call then continues through the system as normal, but with the augmented/altered identity information present.

The key/value pairs are specified using [URL encoding](http://www.w3.org/TR/html5/forms.html#url-encoded-form-data) - percent-escaped special characters, a "`=`" character between keys and values and a "`&`" character separating the pairs. For example:

```
X-Assume-Identity-Of: account_id=account1&member_id=member%20number%203
```

...to yield a Session identity section containing any prior data merged/overwritten with:

```json
{
  "account_id": "account1",
  "member_id":  "member number 3"
}
```

This would be an extremely dangerous header without other safeguards, since it would allow an API caller to masquerade as any identity in the entire system without limit. To avoid such a large security risk, the Session's associated [Caller](#caller.resource) must include rules that describe the allowed key/value pair data in the HTTP header. If these rules are absent or prohibit one or more of the attempted key/value pairs used, a 403 `platform.forbidden` response will be returned. See the [Caller resource documentation](#caller.resource) for more information about the rule definiton and behaviour.



### <a name="security"></a>Security

#### <a name="access_security"></a>Access security

Generic Hoodoo access security is handled by the [Authentication API](#authentication.api) through which API callers acquire [Sessions](#session.resource) that give them various abilities. The Session includes:

* _Identity_ of an API caller, in terms of their [Caller](#caller.resource) ID and any other common fields defined by the wider platform-specific API; for example, some kind of user or member ID might be included here, subject to the implementation of the session system by that platform.

* _Permissions_ controlling which resource(s) the API caller can address and which actions they can request from those resources.

* _Scoping_ which, for a permitted resource, limits the data revealed to the caller. This is related to identity. As an example, a user with a particular user ID might upload Photos. They would only be able to see their Photos by, as a Caller, only having scoping which lets them "see" photos uploaded under their ID. For more about this, [see below](#scoping_and_resource_representation).

You should read the [Authentication API](#authentication.api) information about [Callers](#caller.resource) and [Sessions](#session.resource) to gain an understanding of how this fits together.

##### <a name="scoping_and_resource_representation"></a>Scoping and resource representation

The scoping mechanism limits the data that a [Caller](#caller.resource) can access. Some Callers are able to see data from multiple creating identities and, for those, it is often useful to know which calling identity was responsible for creating (say) a particular resource instance under consideration. Taking an [earlier example](#access_security):

* Suppose we have Users who upload Photos and let one or more Users work within an Account.
* Each User calling the API would do so under a Session with an associated Caller that contains an identity telling the system which User they are.
* The persistence layer for Photos would remember the User ID from the session's identity when creating a new Photo entry.
* When _reading_ Photos, the _scoping_ part of the session would be consulted:
  * If the Caller in use were being maintained by the system so that its scoping only contained one User ID, then a User could only see their own photos, regardless of whoever else was in their Account.
  * If the Caller in use were being maintained by the system so that its scoping contained all User IDs on the Account, then any User on that Account could see the photos for any other User.

In a real-world graphical interface for this hypothetical system, a list of photos from an entire Account probably needs to have information about the owning User provided too. For resources using Hoodoo for data security "under the hood", a standard mechanism is available to reveal the identifier used to filter access to a particular resource - the `secured_with` common resource field is used. Canonically, it is just a field with an object value that can contain any information:

```javascript
"id": "<some UUID>",
"kind": "Resource",
"created_at": "<some date/time>",
"secured_with": {
  "<security field>": "<security value>"
},
// ...
```

A example Photo using User-based scoping would give the UUID of the creating User (as recorded by the session's identity, obtained from the associated Caller) as follows:

```javascript
"id": "<some UUID>",
"kind": "Photo",
"created_at": "<some date/time>",
"secured_with": {
  "user_id": "<User UUID>"
},
// ...
```

#### <a name="data_presentation_security"></a>Data presentation security

Data passed to the platform is in many cases stored verbatim. If there are calls into the system which include odd things like bits of HTML or JavaScript in attempts to mount some sort of attack, then, whether the calls succeeded or failed, at some level in the system the original input data _will_ be recorded.

This means that such data could be _retrieved_ if reading back things like log entries or successfully created resources resulting from the kinds of calls described.

If you are building a user interface around the API, it is ***vital*** therefore that you sanitise such data before display. Failing to do so could lead to all sorts of vulnerabilities in your application. This is a matter of standard practice and good coding in API client applications and not something over which the platform API has any control.



### <a name="cors"></a>CORS support

CORS support is required for API callers running client-side inside JavaScript in a web browser. This is _strongly discouraged_ as it significantly increases the potential security vulnerability attack surface, especially in relation to Session IDs. It's really viable only if you restrict client-side JavaScript to public interfaces that don't require sessions. In any case, should you absolutely require it, you will need a web browser which supports CORS and runs preflight requests to gain access to resources running in another domain. See:

* http://www.w3.org/TR/cors/
* http://www.w3.org/TR/cors/#preflight-request
* http://enable-cors.org

The web browser itself is responsible for transparently issuing the CORS request when needed automatically, understanding the CORS response, knowing that it _is_ a CORS response and adjusting its domain access sandbox for JavaScript code accordingly. In this request:

* The `Origin` HTTP header must be present with a non-empty value which will be quoted back in the `Access-Control-Allow-Origin` response header. The web browser is responsible for setting and sending this automatically - if it fails to do so, the preflight request will fail.
* The `Access-Control-Request-Method` HTTP header must he present, with a value of the HTTP method you intend to use (in capitals - any one of `GET`, `POST`, `PATCH` or `DELETE`. A full set of permitted methods are quoted back in the `Access-Control-Allow-Methods` HTTP header.
* The `Access-Control-Request-Headers` HTTP header must be present, since all API calls require at least `Content-Type` header to be provided; the CORS request must ask for this. Most API calls require an `X-Session-ID` header too, so the CORS request probably asks for that as well. The value is quoted back in the `Access-Control-Allow-Headers` response header.
* Obviously there is no `X-Session-ID` header required _in the preflight request itself_, as the `OPTIONS` HTTP method yields no access to any resources. The preflight request is asking for _permission_ to use that header in a request.

A good article on the browser's side of CORS is available from MDN at [https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS).

Example HTTP request:

```http
OPTIONS http://api.test.com/v1/sessions/ HTTP/1.1
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, X-Session-ID
Origin: https://localhost:8080
```

Example HTTP response:

```http
HTTP/1.1 200 OK
Content-Length: 0
X-Interaction-ID: 28ea7b57310f49eebbc68ab89f79dfe2
Content-Type: application/json; charset=utf-8
Access-Control-Allow-Origin: https://localhost:8080
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, X-Session-ID
Date: Wed, 12 Aug 2015 01:02:48 GMT
Connection: close
```

Something along those lines _should happen automatically_ when the browser executes JavaScript code such as this attempt to create a hypothetical "Example" resource instance:

```javascript
var xhr = new XMLHttpRequest;

xhr.open( 'POST', 'https://api.example.com/v1/examples', true );
xhr.setRequestHeader( 'Content-Type', 'application/json; charset=utf-8' );
xhr.onreadystatechange = handler;
xhr.send( '{ "example_field": "hello, world" }' );

function handler()
{
  alert( xhr.status + ' - ' + xhr.readyState );
}
```

The use of a cross-domain `POST` attempt should trigger a CORS preflight request "behind the scenes" which, if all is well, allows your _actual_ request to then be sent.

If you have trouble, check your browser's JavaScript debugging console for information on what might be going wrong. At the time of writing, XHR requests seem easier to initially debug with Firefox as its console messages contain the most useful information about the nature of the problem.

**Important**: The presence of values for allowed methods or headers in the response only grants theoretical access to cross-domain JavaScript code. It does *not* mean that the credentials you are using will give you a session that has permission to use all of those facilities and not all resource endpoints will support all of the HTTP verbs or headers given in the response in any case. Only the [`X-Resource-UUID`](#http_x_resource_uuid) header is _never_ permitted for cross-domain JavaScript code, regardless of the caller's permissions; and _no special response headers_ are allowed to be seen by JavaScript code at any time, including `X-Interaction-ID`.

**Important**: As mentioned above, client-side JavaScript making API calls is _strongly discouraged_ as recovery of a session ID becomes very easy and this may allow attackers to perform damaging actions under your session permissions that you do not expect, depending upon the session's resource access permissions. It is _far, far safer_ to hide all that on your server side through server-implemented actions which can be invoked if necessary by same-origin JavaScript code on the client side.



## <a name="authentication.api"></a>Authentication API

Hoodoo does not implement any resource endpoints itself, but for consistency and due to the deeply integrated security model, the authentication system needs to be specified. **It is up to platform providers to provide a compliant implementation** if they want to use the Hoodoo security model as written, though you may choose to break away and offer an entirely bespoke solution.



### <a name="authentication.api.types"></a>Data Types

The Authentication API describes a way to define a set of allowed behaviour for known API clients through the [Caller resource](#caller.resource), which amongst other configuration data, includes all or a subset of a collection of permissions-related data types defined below. It actually describes both authentication ("what a caller can do") and authorisation ("who a caller is") functionality.

The references to actions being allowed on resources herein are made in the context of a calling API client that is operating within the permissions constraints of the Caller resource instance with which they are associated. This association is made by creating a [Session resource instance](#session.resource) and passing that resource's identifier as the value of the `X-Session-ID` HTTP header in each and every subsequent API call.

#### <a name="permissions.type"></a>Permissions `::type::permissions`

An abstract representation of the policies applied for actions.

```javascript
{
  "actions": {
    "{show|list|create|update|delete}": "{allow|deny|ask}",
    // ...
  },
  "else": "{allow|deny|ask}"
}
```

Inside the `actions` section, a key based off an action name leads to a value of:

* `allow` - the action is allowed unconditionally.
* `deny` - the action is prohibited unconditionally.
* `ask` - a resource endpoint implementation may apply additional logic based on the inbound request and allow or deny it dynamically. Valid use of this is rare. Resource documentation herein clearly states if a policy of `ask` can be used, else it _must not_ be.

When considering whether or not a given action is allowed, the system first examines the `actions` section. If this does not have a key named after the action at hand, the `else` condition fallback is consulted instead.

As a general rule, in the event that a specific applicable permission policy for an inbound request cannot be determined, the default behaviour is to deny that request (but see also the [PermissionsDefaults](#permissions_defaults.type) Type).



#### <a name="permissions_resources.type"></a>PermissionsResources `::type::permissions_resources`

A representation of the policy to apply for actions performed on particular identified resources.

```javascript
{
  "resources": {
    "{resource-name}": {::type::permissions},
    // ...
  }
}
```

For example consider the following resource permissions:

```javascript
{
  "resources": {
    "Member": {
      "actions": {
        "show": "allow",
        "list": "allow"
      },
      "else": "deny"
    }
  }
}
```

This allows showing and listing of Member instances, but denies any _other action_ for _that same_ resource. Any _other resource_ that a request might target falls under the default behaviour of denying the request, subject to any [PermissionsDefaults](#permissions_defaults.type) that might apply.



#### <a name="permissions_defaults.type"></a>PermissionsDefaults `::type::permissions_defaults`

A representation of the policy to apply for actions for any resource not already described by any applicable [PermissionsResources](#permissions_resources.type) data.

```javascript
{
  "default": {::type::permissions}
}
```

For example consider the following default permissions:

```javascript
{
  "default": {
    "actions": {
      "show": "deny",
      "list": "deny"
    },
    "else": "allow"
  }
}
```

This prohibits showing and listing of any otherwise-unspecified resource, but allows every other action.



#### <a name="permissions_full.type"></a>PermissionsFull `::type::permissions_full`

A representation of a complete set of policies for actions upon specified resources along with default fallbacks.

```javascript
{
  {::type::permissions_resources},
  {::type::permissions_defaults}
}
```

For example consider the following full set of permissions:

```javascript
{
  "resources": {
    "Member": {
      "actions": {
        "show": "allow",
        "list": "allow"
      },
      "else": "deny"
    }
  },
  "default": {
    "actions": {
      "show": "deny",
      "list": "deny"
    },
    "else": "allow"
  }
}
```

This allows showing and listing of Member resources, but prohibits other Member resource actions. For any non-Member resource, the defaults are used; showing and listing is prohibited, other actions are allowed.

When considering full such permissions, the system:

* Looks for a resource-and-action-specific policy;
* Looks for the resource-specific `else`;
* Looks for the default action-specific policy;
* Looks for the default `else`;
* Otherwise denies the request.



### <a name="authentication.api.resources"></a>Resources

#### <a name="caller.resource"></a>Caller `::resource::caller`

A `Caller` is a representation of some actor which interacts with the Loyalty Platform API. The generic representation is as follows:

```javascript
{
  "kind":                  "Caller",
  "id":                    "{uuid}",
  "created_at":            "{datetime}",

  "authentication_secret": "{string}", // Only retrievable when creating; see POST description
  "name":                  "{string}", // Optional, for a human to understand what a Caller is for

  "identity": {
    // Domain-defined by derived customised resource variants
  },

  "permissions": {
    {::type::permissions_resources}, // Fields are *inline*
  },

  "scoping": {
    // Domain-defined by derived customised resource variants, plus
    // standardised optional entries:

    "authorised_http_headers": [ "{string}", ... ],
    "authorised_identities":   {identity-map}
  }
}
```

The Caller's `authentication_secret` is a value that _only the intended user of this Caller instance must ever know_. The value is only returned when a Caller resource instance is _created_ and can _never be retrieved again_ by any mechanism. If you lose a Caller's secret, the Caller instance becomes useless. If a Caller's UUID and secret are known, then a [Session](#session.resource) can be created to make API calls under that Caller's identity. If a malicious third party learned these values, they could "impersonate you" with potential for _substantial_ financial repercussions. Consequently, a Caller's secret *MUST NEVER, EVER* be made public or transmitted over insecure communications channels such as e-mail, plain FTP or plain HTTP. Use things like SFTP, HTTPS, or PGP encryption and minimise the number of places that the secret is known.

The resource contains an `identity` section that in the generic description of a Caller contains no information, because the significance of quantities in terms of identity is up to individual APIs to define. From an [earlier example](#access_security) with User and Photo resources, a `user_id` field would go here. The implementation for that photo management example platform of the Caller resource endpoint would document, require and understand this quantity.

The embedded [PermissionsResources](#permissions_resources.type) data describes "what you can do" at a high level - the basic set of resources it can access and the actions it can perform upon those resources. The default behaviour cannot be specified at this time - any unspecified resource action will always be denied by default.

Within this permissions constraint, the `scoping` section can contain further domain-defined fields as with the `identity` section. There are very few reserved, generic entries:

* `authorised_http_headers`: This supports some [special HTTP headers](#special_http_headers) used to provide unusual functionality to special case callers. Some of these are _secured_ and only permitted when a Session is related to a Caller that includes a particular header in its `authorised_http_headers` array. Currently the following HTTP headers have meaning in the `authorised_http_headers` array:

  * [`X-Resource-UUID`](#http_x_resource_uuid)
  * [`X-Assume-Identity-Of`](#http_x_assume_identity_of)

* `authorised_identities`: Information on identities which are allowed to be assumed via the [`X-Assume-Identity-Of`](#http_x_assume_identity_of) secured header. See the [identity map section later](#caller.resource.interface.identity_maps) for details.

##### <a name="caller.resource.interface"></a>Interface

| HTTP method | Endpoint        | Result |
|-------------|-----------------|--------|
| `POST`      | /callers/       | Create new Caller instance |
| `GET`       | /callers/       | Obtain list of Caller representations |
| `GET`       | /callers/{uuid} | Obtain representation of identified Caller instance |
| `PATCH`     | /callers/{uuid} | Update representation of identified Caller instance |
| `DELETE`    | /callers/{uuid} | Effectively delete identified Caller instance |

* The `GET` 'list' call accepts [common query string parameters](#lppsf).
* No additional sort fields are defined.
* No special search or filter fields are defined in the generic case.
* No resources are embeddable.

Domain-specific variants of the Caller resource implemented within platforms may state scoping rules and/or provide additional search/filter abilities.

To create an instance, `POST` this JSON data:

```javascript
{
  "name": "{string}", // Optional, for a human to understand what a Caller is for

  "identity": {
    // Domain-defined by derived customised resource variants
  },

  "permissions": {
    {::type::permissions_resources}, // Fields are *inline*
  },

  "scoping": {
    // Domain-defined by derived customised resource variants, plus
    // standardised optional entries:

    "authorised_http_headers": [ "{string}", ... ],
    "authorised_identities":   {identity-map}
  }
}
```

The response to a `POST` will include a generated `authentication_secret`. ***The `authentication_secret` must be stored as it is not retrievable via any subsequent API calls or by Loyalty NZ. Loss of the `authentication_secret` will mean a new Client must be created.***

Only a subset of fields may be modified - in particular, note that the `identity` section is immutable. To alter an existing Caller, `PATCH` this JSON data:

```javascript
{
  "name": "{string}", // Optional, for a human to understand what a Caller is for

  "permissions": {
    {::type::permissions_resources}, // Fields are *inline*
  },

  "scoping": {
    // Domain-defined by derived customised resource variants, plus
    // standardised optional entries:

    "authorised_http_headers": [ "{string}", ... ],
    "authorised_identities":   {identity-map}
  }
}
```

**Note:** When a Caller instance is modified or deleted, the platform provider's implementation should ensure that any [Sessions](#session.resource) that refer to the Caller will automatically be invalidated.

###### <a name="caller.resource.interface.identity_maps"></a>Identity maps

The optional `authorised_identities` entry in the `scoping` section of the Caller resource describes an _identity map_ used by the implementation of the [`X-Assume-Identity-Of`](#http_x_assume_identity_of) secured HTTP header. This header lets an API caller specify an alternative identity for use in that one call. The key/value pairs expressed in the HTTP header's value are validated against the identity map.

The identity map operates on a whitelist basis. Given that the associated HTTP header's aim is to change key/value pairs inside the session identity, the map specifies the keys you can specify and provides lists of the values permitted for those keys. The map can be deeply nested, so that particular values of particular keys may in turn allow only particular other values of other keys.

Due to the arbitrary potential key and value contents of the map given the generic use of identity information is up to the implementation of the Caller and Session resources and the meaning therein is API domain-specific, there is no formalised Type defined for the identity map; it is best described by example.

Suppose we had _accounts_ containing one or more _members_ who own one more _devices_. We normally might set up one Caller for every device, with each Caller giving a value for device ID, member ID and account ID as its identity. For any unique combination, a unique Caller is defined so that a Session can be obtained using the Caller credentials. If a Caller's credentials are leaked, only that account/member/device combination is compromised. This is secure, but clumsy; for some special case (probably internal administrative) reason, we decide to define one Caller which can be used to assume the identity of other accounts/members/devices.

The identity map is explicitly designed to make it impossible to define a Caller which can adopt _any_ identity. We must know up-front the IDs that will be permitted.

In the simple case, we could just list these out in a flat identity map. The scoping part of the [Caller](#caller.resource) definition might look like this:

```json
{
  "scoping": {
    "authorised_identities": {
      "account_id": [ "account1", "account6", "account94" ],
      "member_id":  [ "member3", "member4", "member12", "member124" ],
      "device_id":  [ "device1", "device3", "device9", "device102" ]
    }
  }
}
```

Note now each key's value _must_ be an array - even if it only has one entry - of the allowed identities that can be assumed for each of those named entries. The keys in the identity map match the keys permitted in the key-value pairs given with the HTTP header; the arrays of values in the identity map give the permitted individual values for the key-value pairs given with the HTTP header. Thus:

```
X-Assume-Identity-Of: account_id=account1&member_id=member3&device_id=9
```

Partial identity overrides are permitted:

```
X-Assume-Identity-Of: account_id=account94
```

In this example, our model for the account/member/device example is a hierarchy. The 'flat' identity map above allows an errant API caller to assume an identity where, say, the given member does not belong to the given account. Given you must know the permitted values up-front, you must also know the hierarchy up-front; you can provide a more nested identity map that describes it:

```json
{
  "scoping": {
    "authorised_identities": {

      "account_id": {

        "account1": {
          "member_id": {
            "member3": {
              "device_id": [ "device1" ]
            },
            "member4": {
              "device_id": [ "device3", "device9" ]
            }
          }
        },

        "account6": {
          "member_id": [ "member12" ]
        },

        "account94": {
          "member_id": {
            "member124": {
              "device_id": [ "device102" ]
            }
          }
        }
      }
    }
  }
}
```

This is a complex example with three levels of nesting. At the top level only `account_id` is given; if the HTTP header is in use at all, it must specify a least an `account_id` key and value. Note how the entry for `account_id` now has a sub-object instead of an array, with now _keys_ listing the allowed account IDs. For each of those allowed IDs, values are in essence a nested identity map framgent. We can look up the next thing which is allowed - `member_id`. In the case of the first and last accounts, there's even another level - the devices - but `account6` only has one member, `member12` and that member has no devices, so the structure just ends at a single-element array giving the permitted ID.

With the updated map, the following header specification would be valid:

```
X-Assume-Identity-Of: account_id=account1&member_id=member3&device_id=device1
```

The next example would not be valid, because `account1` does not contain `member124` - the identity map shows that member under `account94`:

```
X-Assume-Identity-Of: account_id=account1&member_id=member124
```

As before, partial specification is OK; we might just give the account ID:

```
X-Assume-Identity-Of: account_id=account94
```

We cannot just give, say, a member ID though; there is no top-level `member_id` key, so even though `member12` used below does appear in the identity map, there's no way to find it without an accompanying `account_id`:

```
X-Assume-Identity-Of: member_id=account12
```

So an identity map consists of an Object with:

* Keys that describe same-named keys allowed in the [`X-Assume-Identity-Of`](#http_x_assume_identity_of) header value's key/value pair keys.
* Values that at the furthest depth of used nesting must be arrays of permitted values in the header value's key/value pair values.
* Values that alternatively are sub-objects describing a deeper level of nesting. In those sub-objects, keys describe the permitted header value's key/value pair values, and the values describe the nested identity map fragment to use if that value is detected.
* To put it another way, you can see from the above that there's nesting pattern of alternating "permitted key, permitted value(s), permitted key, permitted value(s)..." all the way down to the final deepest part anywhere in the map which must be an array of permitted values.

Placing a given header value's permitted key at more than one level in the map may provoke undefined behaviour, or at best be very confusing! This is not recommended. For example:

```javascript
{
  "scoping": {
    "authorised_identities": {

      "account_id": {
        "account1": {
          "member_id": {
            "member3": {
              // etc., as before
            }
          }
        }
        // etc., as before
      },

      "device_id": [ "device1", "device3", "device9", "device102" ]
    }
  }
}
```

This map includes the same nested data as before, but would also allow an HTTP header to request an assumed identity of just a `device_id` value from the array _as well as_ using an account ID, member ID and device ID permitted by the nested part of the map. This may have unintended consequences. The best approach is to only ever provide a particular key at a particular level in the map, for deterministic and understandable behaviour.

Finally, beware the combination of the Caller's own saved identity and the possibilities for assumed identities, if it defines any, when those assumed identities may not be fully specified (e.g. only an account ID is given and nothing else). The assumed values are merged on top of anything the Caller already defines, so you might still have a vector for accidental code errors yielding invalid identity key/value entry combinations. It may be best to have a specialised Caller with no defined identity of its own, with non-null constraints in any places where identity matters to your resource implementations to catch cases where assumed identity is in use, but incomplete.



#### <a name="session.resource"></a>Session `::resource::session`

**Important:** POSTing to this resource does not require inclusion of the `X-Session-ID` header field.

Permissions and other Caller information which apply to the user of a `Session` instance.

```javascript
{
  "kind":       "Session",
  "id":         "{uuid}",
  "created_at": "{datetime}",

  "caller_id":  "{uuid}",
  "expires_at": "{datetime}" // When this session expires
}
```

The session is considered expired if the current time is greater than or equal to `expires_at`. Sessions expire _at most_ after two days, but may expire sooner if other platform activity causes them to be invalidated (see later).

##### <a name="session.resource.interface"></a>Interface

| HTTP method | Endpoint         | Result |
|-------------|------------------|--------|
| `POST`      | /sessions/       | Create new Session instance |
| `GET`       | /sessions/{uuid} | Obtain representation of identified Session instance |
| `DELETE`    | /sessions/{uuid} | Delete Session instance |

* API callers can only delete or show their own Session.
* The `GET` 'list' call accepts [common query string parameters](#lppsf).
* No additional sort fields are defined.
* No search or filter fields are defined.
* The [Caller](#caller.resource) resource is embeddable via `caller`.

To create an instance, `POST` this JSON data:

```javascript
{
  "caller_id":            "{uuid}",
  "authentication_secret": "{string}"
}
```

An `X-Session-ID` HTTP header is (obviously) _not_ required for this operation. The `caller_id` is the `id` value (UUID) of a [Caller](#caller.resource) instance, which must exist. The `authentication_secret` is that Caller's secret value. The new Session will inherit the identity and abilities of that Caller. If that Caller is changed or deleted, any Sessions referring to it will be automatically invalidated.

When a new Session is created, the returned Session representation's `id` value (UUID) should be sent as the `X-Session-ID` HTTP header value in subsequent API calls. This is how your API calls are matched to a valid (or not!) Session inside the platform and in turn the abilities and identity of "you" are known as a referenced Caller.



## <a name="analytical.api"></a>Analytical API

As with the [Authentication API](#authentication.api), Hoodoo does not implement any resource endpoints itself. It does however always return well-formed Errors instance representations when reporting problems back to API callers. These instances typically include a UUID, but if Hoodoo does not implement a resource endpoint, how are those instances persisted?



### <a name="analytical.api.persistence"></a>Persistence

#### <a name="analytical.api.persistence.information_for_callers"></a>Information for API callers

Log and error data may or may not be retrievable by a resource-based API. The API documentation for your target platform should let you know one way or another. Whether or not an API exists to retrieve previously reported error data, the Type and resource described in this section are still always going to be used by Hoodoo services in their returned representations of errors.

#### <a name="analytical.api.persistence.information_for_providers"></a>Information for API providers

Hoodoo assigns UUIDs to error messages up-front, via UUIDs associated with `error` level log entries, so persisting an error report is akin to persisting any other log item. Thus, Hoodoo automatic logging can be used to provide the basis of a persistence mechanism; **but Hoodoo does not persist log entries itself**. Persistence options include:

* Use a queue-based system, e.g. HTTP-over-AMQP with [Alchemy Flux](https://github.com/LoyaltyNZ/alchemy-flux) and log to the queue. Have an Alchemy process somewhere which listens for logging queue messages and persists them in appropriate formats for e.g. log or Errors resource recovery at a later date. You may choose to persist data indefinitely in the case of errors. You may need to apply rate limiting somewhere in the chain to avoid DOS vulnerabilities.

  This is a centralised approach:

  * Good: Code and configuration changes only happen once, in the queue-listening writer component.
  * Bad: The component represents a single point of failure, which could lead to queued log messages backing up and consuming a lot of memory but at least messages on a queue haven't yet been lost, so there's a chance of restarting the writer and persisting the pending queued messages without data loss.

* Write a custom logger class and use this as a route for persistence. See [Hoodoo Guides](http://loyaltynz.github.io/hoodoo/index.html) for details.

  This is a decentralised approach:

  * Good: It doesn't require or risk overloading any queueing mechanism and a failure of a logging component in one service application process would not affect logging in other independent service application processes.
  * Bad: Configuration or code changes have to be rolled out across all services, individual service logging failures may be harder to detect as other logging data would still be reported and individual service logging failures might cause complete loss of log data.

For the benefit of callers to your API, ideally an [Errors resource endpoint](#errors.resource) will be made available which is compliant with the resource description [below](#errors.resource). Depending on your API's problem domain this facility might be very important or nothing more than a nice-to-have. A conventional Hoodoo-based front-end service with only read-only actions supported can be used to retrieve information from the shared back-end persistent storage used by one of the above options, presenting log data as raw log resources of some kind, of reframing error-level log data as [Errors resource instances](#errors.resource). **Remember to think carefully about data access security and scoping** - you probably don't want to let one person or group accessing your system to be able to access log or error data created on behalf of an entirely separate person or group.



### <a name="analytical.api.types"></a>Data Types

#### <a name="error_primitive.type"></a>ErrorPrimitive `::type::error_primitive`

The ErrorPrimitive Type provides details of one specific failure, in terms of:

* A resource/domain/service-specific error code (API calls describe possible returned codes on a case-by-case basis).
* An `en-GB` encoded error string intended for programmer convenience and not, usually, user interface display since it is locked into a single language.
* An optional error reference data which, if present, is also described on a resource/domain/service-specific basis.
* Each ErrorPrimitive has a default associated HTTP status code.

```javascript
{
  "code":      "{string}", // Error Code
  "message":   "{string}", // en-GB Error message
  "reference": "{string}"  // Error reference data (optional)
}
```

API calls return details of error conditions through one or more of these objects wrapped in an [Errors resource](#errors.resource) representation. The HTTP status code used in the response representing such a collection of errors is taken from the first ErrorPrimitive entry in the Errors resource array of primitives.



### <a name="analytical.api.resources"></a>Resources

#### <a name="errors.resource"></a>Errors `::resource::errors`

The errors resource contains one or more [ErrorPrimitive Types](#error_primitive.type) in an array.

```javascript
{
  "kind":           "Errors",
  "id":             "{uuid}",
  "created_at":     "{datetime}",

  "interaction_id": "{uuid}",
  "errors":         [
    {::type::error_primitive},
    // ...
  ]
}
```

##### <a name="errors.resource.interface"></a>Interface

If a platform creator chooses to provide an Errors resource endpoint, the recommend interface is as follows:

| HTTP method | Endpoint       | Result |
|-------------|----------------|--------|
| `GET`       | /errors/       | Obtain list of Error representations (for all time) |
| `GET`       | /errors/{uuid} | Obtain representation of identified Error instance |

* The `GET` 'list' call accepts [common query string parameters](#lppsf).
* No additional sort fields are defined.
* No search or filter fields are defined.
* No resources are embeddable.

It is likely to be helpful if you augment this with your own selection of search and filter strings. For example, you might allow someone to search for a particular `interaction_id` or list Errors instances that contain a particular error `code` somewhere in their payload.



## <a name="change_history"></a>Change history

| Date       | Version            | Author             | Summary |
|------------|--------------------|--------------------|---------|
| 2015-12-10 | Release 1          | ADH                | Created by splitting out content from an internal API document. |
| 2016-01-14 | Release 2          | ADH                | Clarified use cases for `platform.forbidden`. Added description of `X-Assume-Identity-Of` and related `authorised_identities` identity map data in a Caller resource. |
