# Hoodoo and environment variables

## Overview

Various environment variables can be used to override defaults or otherwise modify Hoodoo behaviour, typically in the context of a service based upon the Hoodoo middleware. During development, these would usually be specified on the command line when launching a service, e.g.:

    SOME_ENV=some_value bundle exec rackup

...or, if using Guard https://github.com/guard/guard with Guard-Shotgun https://github.com/rchampourlier/guard-shotgun:

    SOME_ENV=some_value bundle exec guard

## Environment variable list

| Variable | Use |
|:---------|:----|
| `AMQ_ENDPOINT` | Used by Alchemy to determine the location of the AMQP server; its presence is taken by Hoodoo to indicate that a queue-based environment is in use. |
| `AMQ_LOGGING_ENDPOINT` | If running in an AMQP/Alchemy based environment, service log data is sent to queue name `platform.logging` by default, unless you set this variable to an alternative queue name. |
| `MEMCACHE_URL` | Used by the service session engine and the Dalli gem to talk to a Memcached instance at the indicated URL. If absent, Hoodoo assumes that Memcached is not available. |
| `HOODOO_TEST_SESSION_ROLES` | If Hoodoo' service session engine is in testing mode (used when Memcached is not available, or if `Hoodoo::SessionSession::testing(...)` is used to force it on), this variable overrides the default empty roles string for the test session so you can set role data in the test session structure. |
| `HOODOO_MIDDLEWARE_DRB_PORT_OVERRIDE` | When running in a non-queue (traditional HTTP) environment under local machine development, inter-resource calls made between independent service application instances are possible because a DRb-based daemon is launched behind the scenes and all services talk to this to register the location of their endpoints. They must all agree on the port number to use for contacting this daemon. By default it is 8787, or override with this environment variable. When a service application starts, its Hoodoo middleware instance will detect the new port and start a DRb daemon on that port if no existing daemon is already listening there. |
