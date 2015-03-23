########################################################################
# File::    request.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A high level description of a client's request, with all of
#           the "raw" Rack request data parsed, verified as far as
#           possible and generally cleaned up. Instances of this class
#           are given to Hoodoo::Services::Implementation methods for
#           each new request.
# ----------------------------------------------------------------------
#           24-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services

  # Instances of the Hoodoo::Services::Request class are passed to service
  # interface implementations when requests come in via Rack, after basic
  # checks have been passed and a particular interface implementation has
  # been identified by endpoint.
  #
  # Descriptions of default values expected out of accessors herein refer
  # to the use case when driven through Hoodoo::Services::Middleware. If the
  # class is instantiated "bare" it gains no default values at all (all
  # read accessors would report +nil+).
  #
  class Request

    # Encapsulation of all parameters related only to modifying a
    # list of results. Other parameters may modify lists too, but they
    # also modify other representations (e.g. single-resource 'show').
    #
    class ListParameters

      # List offset, for index views; an integer; always defined.
      #
      attr_accessor :offset

      # List page size, for index views; an integer; always defined.
      #
      attr_accessor :limit

      # List sort key, for index views; a string; always defined.
      #
      attr_accessor :sort_key

      # List sort direction, for index views; a string; always defined.
      #
      attr_accessor :sort_direction

      # List search key/value pairs as a hash, all keys/values strings; {}
      # if there's no search data in the request URI query string.
      #
      attr_accessor :search_data

      # List filter key/value pairs as a hash, all keys/values strings; {}
      # if there's no filter data in the request URI query string.
      #
      attr_accessor :filter_data

      # Set up defaults in this instance.
      #
      def initialize
        self.offset         = 0
        self.limit          = 50
        self.sort_key       = 'created_at'
        self.sort_direction = 'desc'
        self.search_data    = {}
        self.filter_data    = {}
      end
    end

    # Requested locale for internationalised operations; +"en-nz"+ by
    # default.
    #
    attr_accessor :locale

    # Parsed payload hash, for create and update actions only; else +nil+.
    #
    attr_accessor :body

    # An array of zero or more path components making up the URI *after* the
    # service endpoint has been accounted for. For example, with a service
    # endpoint of "products", this URI:
    #
    #     http://test.com/v1/products/1234/foo.json
    #
    # ...would lead to this path component array:
    #
    #     [ '1234', 'foo' ]
    #
    # The first element of the path components array is exposed in the
    # read-only #ident accessor.
    #
    attr_reader :uri_path_components

    # Set the array returned by #uri_path_components and record the first
    # element in the value returned by #ident.
    #
    # +ary+:: Path component array to record. If +nil+ or not an array,
    #         +nil+ is stored for uri_path_components and #ident.
    #
    def uri_path_components=( ary )
      if ary.is_a?( ::Array )
        @uri_path_components = ary
        @ident               = ary.first
      else
        @uri_path_components = nil
        @ident               = nil
      end
    end

    # The first entry in the #uri_path_components array, or +nil+ if the
    # array is empty. This supports a common case for inter-resource calls
    # where a UUID or other unique identifier is provided through the first
    # path element ("+.../v1/resource/uuid+").
    #
    attr_reader :ident

    # A filename extension on the URI path component, if any, else an empty
    # string. The _first_ dot in the _last_ path component is looked for (see
    # also #uri_path_components), so for example this URI:
    #
    #     http://test.com/v1/products/1.2.3.4/foo.my.tar.gz
    #
    # ...would lead to this URI path extension string:
    #
    #     'my.tar.gz'
    #
    attr_accessor :uri_path_extension

    # The Hoodoo::Services::Request::ListParameters instance
    # associated with this request.
    #
    attr_accessor :list

    # Define a set of now-deprecated accessors that are basically
    # just proxies through to the "list" instance. See #list.
    #
    %i{
      offset
      limit
      sort_key
      sort_direction
      search_data
      filter_data
    }.each do | method |
      define_method( "list_#{ method }" ) do
        list.send( method )
      end

      define_method( "list_#{ method }=" ) do | value |
        list.send( "#{ method }=", value )
      end
    end

    # Array of strings giving requested embedded items; [] if there are
    # none requested.
    #
    attr_accessor :embeds

    # Array of strings giving requested referenced items; [] if there are
    # none requested.
    #
    attr_accessor :references

    # Set up defaults in this instance.
    #
    def initialize
      self.locale              = 'en-nz'
      self.uri_path_components = []
      self.uri_path_extension  = ''
      self.list                = Hoodoo::Services::Request::ListParameters.new
      self.embeds              = []
      self.references          = []
    end
  end

end; end
