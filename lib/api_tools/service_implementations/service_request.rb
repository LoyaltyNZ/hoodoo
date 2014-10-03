########################################################################
# File::    service_request.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A high level description of a client's request, with all of
#           the "raw" Rack request data parsed, verified as far as
#           possible and generally cleaned up. Instances of this class
#           are given to ApiTools::ServiceImplementation methods for
#           each new request.
# ----------------------------------------------------------------------
#           24-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools

  # Instances of the ApiTools::ServiceRequest class are passed to service
  # interface implementations when requests come in via Rack, after basic
  # checks have been passed and a particular interface implementation has
  # been identified by endpoint.
  #
  # Descriptions of default values expected out of accessors herein refer
  # to the use case when driven through ApiTools::ServiceMiddleware. If the
  # class is instantiated "bare" it gains no default values at all (all
  # read accessors would report +nil+).
  #
  class ServiceRequest

    # The originating Rack::Request, in case you want to dive inside it to
    # find something not already abstracted at a higher level by the
    # ApiTools::ServiceRequest class.
    #
    attr_accessor :rack_request

    # Parsed payload hash, for create and update actions only; else +nil+.
    #
    attr_accessor :payload

    # An array of zero or more path components making up the URI *after* the
    # service endpoint has been accounted for. For example, with a service
    # endpoint of "products", this URI:
    #
    #     http://test.com/products/1234/foo.json
    #
    # ...would lead to this path component array:
    #
    #     [ '1234', 'foo' ]
    #
    attr_accessor :uri_path_components

    # A filename extension on the URI path component, if any, else an empty
    # string. The _first_ dot in the _last_ path component is looked for (see
    # also #uri_path_components), so for example this URI:
    #
    #     http://test.com/products/1.2.3.4/foo.my.tar.gz
    #
    # ...would lead to this URI path extension string:
    #
    #     'my.tar.gz'
    #
    attr_accessor :uri_path_extension

    # List offset, for index views; an integer; always defined.
    #
    attr_accessor :list_offset

    # List page size, for index views; an integer; always defined.
    #
    attr_accessor :list_limit

    # List sort key, for index views; a string; always defined.
    #
    attr_accessor :list_sort_key

    # List sort direction, for index views; a string; always defined.
    #
    attr_accessor :list_sort_direction

    # List search key/value pairs as a hash, all keys/values strings; {}
    # if there's no search data in the request URI query string.
    #
    attr_accessor :list_search_data

    # List filter key/value pairs as a hash, all keys/values strings; {}
    # if there's no filter data in the request URI query string.
    #
    attr_accessor :list_filter_data

    # Array of strings giving requested embedded items; [] if there are
    # none requested.
    #
    attr_accessor :list_embeds

    # Array of strings giving requested referenced items; [] if there are
    # none requested.
    #
    attr_accessor :list_references

  end
end
