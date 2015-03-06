

This will just be to return 404s from the case where we know up from from
  discovery that the resource isn't found.

It should probably inherit HTTPBased because it can use the protected
  "return 404" code.
