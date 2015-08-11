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
    end

    # Requested locale for internationalised operations; +"en-nz"+ by
    # default.
    #
    attr_accessor :locale

    # The requested date-time supplied by the caller for calls to show
    # or list resources that support historical representation. If +nil+,
    # the instantaneous internal endpoint target processing time of
    # 'now' is implied.
    #
    attr_reader :dated_at

    # The requested date-time supplied by the caller for calls to create
    # resources, for any resource which supports historical representation
    # retrieval.
    #
    # The historical retrieval code (see method #dated_at in this class, and
    # module Hoodoo::ActiveRecord::Dated) will be able to find the database
    # record for any requested time on or after this date _but not before_.
    # The date may be in the past or future; a record might exist in the
    # database, but not be visible until the dated-from creation time comes
    # to pass.
    #
    # The value is +nil+ if no special creation time is requested - implies
    # whatever value of "now" applies at instant of processing the resource
    # creation action at whatever persistence layer is in use.
    #
    attr_reader :dated_from

    # Writer for #dated_at which accepts a Time instance, DateTime instance
    # or a String; see Hoodoo::Utilities#rationalise_datetime for details -
    # the given input parameter is run through this processing function.
    #
    # Invalid date/time strings can lead to an exception. If you want to
    # avoid catching an exception, use
    # Hoodoo::Utilities#valid_iso8601_subset_datetime? to check a String
    # input type before calling here.
    #
    # +input+:: Time, DateTime or String - run through
    #           Hoodoo::Utilities#rationalise_datetime to generate a
    #           DateTime instance or raise an exception.
    #
    def dated_at=( input )
      @dated_at = Hoodoo::Utilities.rationalise_datetime( input )
    end

    # As #dated_at=, but used to set the value returned by #dated_from.
    #
    # +input+:: As for #dated_at=
    #
    def dated_from=( input )
      @dated_from = Hoodoo::Utilities.rationalise_datetime( input )
    end

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
