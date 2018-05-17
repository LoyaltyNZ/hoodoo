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

      # A Hash of String keys and values, where each key is a field for
      # sorting and each value is the direction to sort that field.
      #
      attr_accessor :sort_data

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
        self.offset      = 0
        self.limit       = 50
        self.sort_data   = { 'created_at' => 'desc' }
        self.search_data = {}
        self.filter_data = {}
      end

      # Represent the list data as a Hash, for uses such as persistence
      # or loading into another session instance. The returned Hash is a
      # full deep copy of any internal data; changing it will not alter
      # the ListParameters object state.
      #
      # Top-level keys in the Hash are Strings corresponding to the names
      # of accessor parameters:
      #
      #   * +"offset"+
      #   * +"limit"+
      #   * +"sort_data"+
      #   * +"search_data"+
      #   * +"filter_data"+
      #
      # Sort, search and filter data, if not empty, also have String keys.
      #
      # See also #from_h!.
      #
      def to_h
        {
          'offset'      => self.offset,
          'limit'       => self.limit,
          'sort_data'   => Hoodoo::Utilities.deep_dup( self.sort_data   ),
          'search_data' => Hoodoo::Utilities.deep_dup( self.search_data ),
          'filter_data' => Hoodoo::Utilities.deep_dup( self.filter_data )
        }
      end

      # Load list parameters from a given Hash, of the form set by #to_h.
      # Overwrites any corresponding internal attributes and takes full
      # deep copies of sort, search and filter values.
      #
      def from_h!( hash )
        self.offset      = hash[ 'offset' ] if hash.has_key?( 'offset' )
        self.limit       = hash[ 'limit'  ] if hash.has_key?( 'limit'  )
        self.sort_data   = Hoodoo::Utilities.deep_dup( hash[ 'sort_data'   ] ) if hash[ 'sort_data'   ].is_a?( Hash )
        self.search_data = Hoodoo::Utilities.deep_dup( hash[ 'search_data' ] ) if hash[ 'search_data' ].is_a?( Hash )
        self.filter_data = Hoodoo::Utilities.deep_dup( hash[ 'filter_data' ] ) if hash[ 'filter_data' ].is_a?( Hash )
      end
    end

    # Requested locale for internationalised operations; +"en-nz"+ by
    # default.
    #
    attr_accessor :locale

    # Define read/write accessors for properties related to "X-Foo"
    # headers. See the Middleware for details.
    #
    Hoodoo::Client::Headers.define_accessors_for_header_equivalents( self )

    # Hash of HTTP headers _in_ _Rack_ _format_ - e.g. +HTTP_X_INTERACTION_ID+
    # for the "X-Interaction-ID" header, for read-only use. All keys are in
    # upper case, are Strings, have "HTTP_" at the start and use underscores
    # where the original request might've used an underscore or hyphen. The
    # usual curious Rack exceptions of +CONTENT_TYPE+ and +CONTENT_LENGTH+ do
    # apply, though. This is a superset of header values including those sent
    # by the client in its request and anything Rack itself might have added.
    #
    attr_accessor :headers

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
      sort_data
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
      self.headers             = {}.freeze
    end
  end

end; end
