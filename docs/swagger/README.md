# Swagger JSON generator for Hoodoo

*Swagger* is a reasonably popular way of describing an API using JSON.

* http://swagger.io
* https://github.com/swagger-api/swagger-spec
* https://editor.swagger.io/
* https://github.com/swagger-api/swagger-ui

This folder contains a generator for a *Swagger 2.0* description of one or more services each containing one or more Resources. The generator is configured through `config.yml`, which is heavily commented to explain what the various sections do. The `paths` and `repositories` parts are probably of most interest.

Run the generator using e.g. `bundle exec make.rb`. Service repositories (if configured) are cloned and the service code is parsed. A Swagger JSON file is dumped into `swagger.json` (or whatever other leafname has been configured) in the current working directory, overwriting any previous file if present.

JSON validation is run over the file but this doesn't guarantee _Swagger_ compliance, just JSON compliance. A reasonable approach is to visit the Swagger editor at https://editor.swagger.io/ and use the "File -> Paste JSON..." (correct at the time of writing) menu entry to paste in the output data.
