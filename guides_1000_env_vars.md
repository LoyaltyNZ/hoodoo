---
layout: default
categories: [guide]
title: Environment Variables
---

## Overview

Various environment variables can be used to override defaults or otherwise modify Hoodoo behaviour, typically in the context of a service based upon the Hoodoo middleware. During development, these would usually be specified on the command line when launching a service, e.g.:

    SOME_ENV=some_value bundle exec rackup

...or, if using [Guard](https://github.com/guard/guard) with [Guard-Shotgun](https://github.com/rchampourlier/guard-shotgun):

    SOME_ENV=some_value bundle exec guard

Hoodoo itself responds to some of these, while the service shell adds a few more that it reads during initialisation. Values are usually cached, so you should restart your service(s) if the values of variables described below are changed.



## Environment variable list

### Hoodoo

#### `AMQ_URI`

Used by Alchemy to determine the location of the AMQP server; its presence is taken by Hoodoo to indicate that a queue-based environment is in use.

#### `AMQ_LOGGING_ENDPOINT`

If running in an AMQP/Alchemy based environment, service log data is sent to queue name `platform.logging` by default, unless you set this variable to an alternative queue name.

#### `AMQ_ANALYTICS_LOGGING_ENDPOINT`

Related to `AMQ_LOGGING_ENDPOINT`, this variable is optional. If defined, its value is used as a RabbitMQ routing key in the case, very specifically, of a message logged with a `code` of `analytics`. If the variable is not set, the same routing key is used for all messages regardless of logged code; else log data using that particular logged code will be streamed off to another Rabbit queue using the given alternative routing key.

If unset, the default value falls back to the routing key determined from `AMQ_LOGGING_ENDPOINT`. If leaning on the default log key of `platform.logging`, the recommended analytics key is `platform.analytics`.

#### `MEMCACHED_HOST`

Used by the service session engine and the Dalli gem to talk to a Memcached instance at the indicated URL. If absent, Hoodoo assumes that Memcached is not available.

#### `HOODOO_TEST_SESSION_ROLES`

If Hoodoo' service session engine is in testing mode (used when Memcached is not available, or if `Hoodoo::LegacySessionSession::testing(...)` is used to force it on), this variable overrides the default empty roles string for the test session so you can set role data in the test session structure.

#### `HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE`

When running in a non-queue (traditional HTTP) environment under local machine development, inter-resource calls made between independent service application instances are possible because a DRb-based daemon is launched behind the scenes and all services talk to this to register the location of their endpoints. They must all agree on the port number to use for contacting this daemon. By default it is 8787, or override with this environment variable. When a service application starts, its Hoodoo middleware instance will detect the new port and start a DRb daemon on that port if no existing daemon is already listening there.

#### <a name="hoodoo_clock_drift_tolerance"></a>`HOODOO_CLOCK_DRIFT_TOLERANCE`

When date-aware mechanisms are in use - for example, the [`X-Dated-At`](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification#http_x_dated_at) and [`X-Dated-From`](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification#http_x_dated_from) HTTP headers - Hoodoo applies a "not in the future" check based on `Time.now`. Since this is the time of the _server on which the Hoodoo service is running_ it is unlikely to exactly match the time of a calling client. Even though use of [NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol) can mean clocks are reasonably accurate, API call rejections may occur if this "in future" check was applied strictly, because the calling client's concept of `now` may well be ahead of the server's concept of `now`, even if only by a small amount.

On multi-node deployments, an inter-resource call to another service might result in a different server node responding, so the same problem can manifest within a higher level API call in confusing ways. For example, an inbound API call might specify no date at all, but the implementation of the resource handling that call may use `Time.now` to lock date-times for inter-resource lookups on downstream dating-aware resources via the `X-Dated-At` header internally. If such a call happened to be handled by a server node with a clock fractionally behind the calling node, then the client might end up receiving a confusing error about an invalid `X-Dated-At` HTTP header even though they not knowingly used one.

Hoodoo v2.2.x and earlier used strict checks so these problems were evident. Workarounds were inelegant and counter-intuitive. Hoodoo v2.3.0 introduced the `HOODOO_CLOCK_DRIFT_TOLERANCE` environment variable which specifies an **integer number of seconds** of allowed drift. If any date-aware system managed by Hoodoo encounters a time that appears to be ahead of `Time.now` but only by *less than or equal to* the specified number of seconds, the call will be permitted. If the requested time exceeds the drift allowance, it will be rejected. A value of zero will give behaviour identical to Hoodoo v2.2.x or earlier but this is **not recommended**.

The default setting in Hoodoo v2.3.0 and later is **30 seconds**.

> Authors of resource implementations that accept and manually range-check "not in future" date-times are encouraged to use method [`Hoodoo::Utilities::is_in_future?`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Utilities.html#method-c-is_in_future-3F), available in Hoodoo v2.3.0 or later, to lean on this mechanism and provide consistent clock drift tolerance across all aspects of the implementation.



### Service shell

#### `DATABASE_URL`

A connection URL used for Active Record database connections _entirely instead of_ `config/database.yml`.

#### `PORT`

If using `guard` to start the service on `localhost`, normally a random spare local machine port will be chosen. You can override this to a fixed, known value with the `PORT` environment variable.

#### Others

If you enable features like New Relic in the shell then potentially a large number of extra variables may become available, such as `NEWRELIC_AGENT_ENABLED`. Consult the vendor documentation for the feature in question to find out more.
