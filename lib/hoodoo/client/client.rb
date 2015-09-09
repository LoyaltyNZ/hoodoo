########################################################################
# File::    client.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Easy communication with Resource implementations.
# ----------------------------------------------------------------------
#           25-Feb-2015 (ADH): Created.
########################################################################

module Hoodoo

  # Hoodoo::Client provides a high-level abstracted interface for making
  # calls to Resource implementations. A Client instance is created and used
  # as a factory for objects representing individual Resources. Callers use
  # a consistent, high level interface in these objects to make requests to
  # those Resources and do not usually need to worry about where
  # implementations are, or how they are being contacted.
  #
  # Please see the constructor documentation for full details.
  #
  class Client

    public

      # Create a client instance. This is used as a factory for endpoint
      # instances which communicate with Resource implementations.
      #
      # == Overview
      #
      # Suppose you have Resources with only +public_actions+ so that no
      # sessions are needed, with resource implementations running at host
      # "test.com" on paths which follow downcase/pluralisation conventions.
      # In this case, creating a Client instance can be as simple as:
      #
      #     client = Hoodoo::Client.new(
      #       base_uri:     'http://test.com/',
      #       auto_session: false
      #     )
      #
      # Ask this client for an endpoint of Resource "Member" implementing
      # version 2 of its interface:
      #
      #     members = client.resource( :Member, 2 )
      #
      # Perform operations on the endpoints according to the methods in the
      # base class - see these for details:
      #
      # * Hoodoo::Client::Endpoint#list
      # * Hoodoo::Client::Endpoint#show
      # * Hoodoo::Client::Endpoint#create
      # * Hoodoo::Client::Endpoint#update
      # * Hoodoo::Client::Endpoint#delete
      #
      # The above reference describes the basic approach for each call, with
      # common parameters such as the query hash or body hash data described
      # in the base class constructor, Hoodoo::Client::Endpoint#new.
      #
      # As an example, we could list records 50-79 inclusive of "Member"
      # sorted by +created_at+ ascending, embedding an "account" for each,
      # where field 'surname' matches 'Smith' - assuming there's an
      # implementation of such a Resource interface available! - as follows:
      #
      #     results = members.list(
      #       :offset    => 50,
      #       :limit     => 25,
      #       :sort      => :created_at,
      #       :direction => :asc,
      #       :embeds    => 'account',
      #       :search    => { :surname => 'Smith' }
      #     )
      #
      # This will return a Hoodoo::Client::AugmentedArray. This is an Array
      # subclass which will contain the (up to) 25 results from the above
      # call and supports Hoodoo::Client::AugmentedArray#dataset_size which
      # (if the called Resource endpoint implementation provides the
      # information) gives the total size of the data set at the time of
      # calling.
      #
      # The other 4 methods return a Hoodoo::Client::AugmentedHash. This is a
      # Hash subclass. Both the Array and Hash subclasses provide a common
      # standard way to handle errors. See the documentation of these classes
      # for details; in brief, you _must_ _always_ check for errors before
      # examining the Hash or Array data with a pattern such as this:
      #
      #     if results.platform_errors.has_errors?
      #       # Examine results.platform_errors, which is a
      #       # Hoodoo::Errors instance, and deal with the contents.
      #     else
      #       # Treat 'results' as a Hash containing the Resource
      #       # data (String keys) or Array of Hashes of such data.
      #     end
      #
      # == Session management
      #
      # By default, the Hoodoo::Client constructor assumes you want automatic
      # session management.
      #
      # If you want to use automatic sessions, a Resource endpoint which
      # implements the Session Resource interface is required. This must
      # accept a POST (+create+) action with a payload of two JSON fields:
      # +caller_id+ and +authentication_secret+. It must return a Resource
      # with an "id" value that contains the session ID to quote in future
      # requests via the X-Session-ID HTTP header; or it should return an
      # error if the Caller ID and/or authentication secret are incorrect.
      #
      # The Resource is assumed to live at the same base URI and/or be
      # discovered by the same mechanism (e.g. by convention) as everything
      # else you'll use the client instance for. For more about discovery
      # related paramters, see later.
      #
      # You will need to provide the +caller_id+ and +authentication_secret+
      # (as named parameter +caller_secret+) to the constructor. If the name
      # of the Resource implementing the Session interface is not 'Session',
      # or not at version 1, then you can also provide alternatives. For
      # example, suppose we want to use automatic session management for
      # Caller ID "0123" and secret "ABCD" via version 2 of "CustomSession":
      #
      #     client = Hoodoo::Client.new(
      #       base_uri:              'http://test.com/',
      #       auto_session_resource: 'CustomSession',
      #       auto_session_version:  2,
      #       caller_id:             '0123',
      #       caller_secret:         'ABCD'
      #     )
      #
      # Finally, you can manually supply a session ID externally for the
      # X-Session-ID header through the +session_id+ parameter. This may be
      # used in conjunction with auto-session management; in that case, the
      # given session is used until it expires (a "platform.invalid_session"
      # error is encountered), after which a new one will be obtained.
      #
      # == Discovery parameters
      #
      # The Client instance needs to be able to find the place where the
      # requested Resource implementations are located, which it does using
      # the Hoodoo::Services::Discovery framework. You should read the
      # description of this framework to get a feel for how that works first.
      #
      # One of the following *named* parameters must be supplied in order to
      # choose a discovery engine for finding Resource endpoints:
      #
      # +base_uri+::              When given, Resource discovery is done by
      #                           Hoodoo::Services::Discovery::ByConvention.
      #                           The path that the by-convention discoverer
      #                           creates is appended to the base URI to
      #                           build the full URI at which a server
      #                           implementing each requested Resource
      #                           endpoint is assumed to be listening (else
      #                           404 / 'platform.not_found' responses will
      #                           arise). Specify as a String. Alternatively,
      #                           use the +drb_uri+ or +drb_port+ options.
      #
      # +drb_uri+::               When given, Resource discovery is done by
      #                           Hoodoo::Services::Discovery::ByDRb (but the
      #                           +base_uri+ option takes precedence over
      #                           DRb options, if provided). A DRb service
      #                           providing discovery data must be running
      #                           at the given URI. Specify as a String. See
      #                           Hoodoo::Services::Discovery::ByDRb::DRbServer
      #                           and file +drb_server_start.rb+ for more.
      #
      # +drb_port+::              Instead of +drb_uri+, you can provide a
      #                           port number for a DRb server on localhost.
      #                           See Hoodoo::Services::Discovery::ByDRb for
      #                           which of +drb_uri+ or +drb_port+ take
      #                           precedence, should both be given. If the
      #                           +base_uri+ option is provided, both
      #                           +drb_uri+ and +drb_port+ will be ignored.
      #
      # +discoverer+::            Use of any of the above options causes
      #                           automatic selection of a Discoverer class
      #                           for routing requests. If required, you can
      #                           create a Hoodoo::Services::Discovery
      #                           subclass instance customised to your own
      #                           requirements and pass this instance here.
      #
      # As an example of using a custom Discoverer, consider a simple HTTP
      # case with the +base_uri+ parameter. The default "by convention"
      # discoverer pluralises all paths, but let's say you have exceptions
      # for Version and Health singleton resources which you've elected to
      # place on singular, not plural, paths. You will need to construct a
      # custom discoverer with these exceptions. See the documentation for
      # Hoodoo::Services::Discovery::ByConvention to understand the options
      # passed in for the custom routing information.
      #
      #     base_uri = 'https://api.test.com/'
      #
      #     discoverer = Hoodoo::Services::Discovery::ByConvention.new(
      #       :base_uri => base_uri,
      #       :routing  => {
      #         :Version => { 1 => '/v1/version' },
      #         :Health  => { 1 => '/v1/health'  }
      #       }
      #     )
      #
      #     client = Hoodoo::Client.new(
      #       :base_uri   => base_uri,
      #       :discoverer => discoverer,
      #       # ...other options...
      #     )
      #
      # == Other parameters
      #
      # The following additional *named* parameters are all optional:
      #
      # +locale+::                The String given in Content-Language HTTP
      #                           headers for requests; default is "en-nz".
      #
      # +session_id+::            An optional session ID to be used for the
      #                           initial X-Session-ID request header value.
      #
      # +auto_session+::          If +false+, automatic session management is
      #                           disabled. Default is +true+.
      #
      # +auto_session_resource+:: Name of the Resource to use for automatic
      #                           session management as a String or Symbol.
      #                           Default is +"Session"+.
      #
      # +auto_session_version+::  Version of the Resource to use for
      #                           automatic session management as an Integer.
      #                           Default is 1.
      #
      # +caller_id+::             If using automatic session management, a
      #                           Caller UUID must be provided. It is used
      #                           as the +caller_id+ field's value in the
      #                           POST (+create+) call to the session
      #                           Resource endpoint.
      #
      # +caller_secret+::         If using automatic session management, a
      #                           Caller authentication secret must be
      #                           provide. It is used as the
      #                           +authentication_secret+ field's value in
      #                           the POST (+create+) call to the session
      #                           Resource endpoint.
      #
      # If curious about the implementation details of automatic session
      # management, see the Hoodoo::Client::Endpoints::AutoSession class's
      # code.
      #
      def initialize( base_uri:              nil,
                      drb_uri:               nil,
                      drb_port:              nil,
                      discoverer:            nil,

                      locale:                nil,

                      session_id:            nil,
                      auto_session:          :true,
                      auto_session_resource: 'Session',
                      auto_session_version:  1,
                      caller_id:             nil,
                      caller_secret:         nil )

        @base_uri = base_uri
        @drb_uri  = drb_uri
        @drb_port = drb_port

        @locale   = locale

        if @base_uri != nil
          @discoverer = discoverer || Hoodoo::Services::Discovery::ByConvention.new(
            :base_uri => @base_uri
          )
        elsif @drb_uri != nil || @drb_port != nil
          @discoverer = discoverer || Hoodoo::Services::Discovery::ByDRb.new(
            :drb_uri  => @drb_uri,
            :drb_port => @drb_port
          )
        end

        if @discoverer.nil?
          raise 'Hoodoo::Client: Please pass one of the "base_uri", "drb_uri" or "drb_port" parameters.'
        end

        # If doing automatic sessions, acquire a session creation endpoint

        @session_id    = session_id
        @caller_id     = caller_id
        @caller_secret = caller_secret

        if auto_session
          @auto_session_endpoint = Hoodoo::Client::Endpoint.endpoint_for(
            auto_session_resource,
            auto_session_version,
            { :discoverer => @discoverer }
          )
        end
      end

      # Get an endpoint instance which you can use for talking to a Resource.
      # See the constructor for full information.
      #
      # You'll always get an endpoint instance back from this call. If an
      # implementation of the given version of the given Resource cannot be
      # contacted, you will only get a 404 ('platform.not_found') or 408
      # ('platform.timeout') response when you try to make a call to it.
      #
      # +resource+:: Resource name as a Symbol or String (e.g. +:Purchase+).
      #
      # +version+::  Endpoint version as an Integer; optional; default is 1.
      #
      # +options+::  Optional options Hash (see below).
      #
      # The options Hash key/values are as follows:
      #
      # +locale+::     Locale string for request/response, e.g. "en-gb".
      #                Optional. If omitted, defaults to the locale set in this
      #                Client instance's constructor.
      #
      # +dated_at+::   Time instance, DateTime instance or String that Ruby can
      #                parse into a DateTime instance used for show/list calls
      #                to resource endpoints that support historical
      #                representation via an <tt>X-Dated-At</tt> HTTP header or
      #                equivalent. If omitted, defaults to +nil+ (no historical
      #                representation requested).
      #
      # +dated_from+:: Time instance, DateTime instance or String that Ruby can
      #                parse into a DateTime instance used for creation calls
      #                to resource endpoints that support creation time
      #                specification via an <tt>X-Dated-From</tt> HTTP header
      #                or equivalent, as part of their support for historical
      #                representation via a <tt>X-Dated-At</tt> HTTP header or
      #                equivalent. If omitted, defaults to the created resource
      #                being created at and thus valid from the server's value
      #                of "now".
      #
      def resource( resource, version = 1, options = {} )

        locale     = options[ :locale     ] || @locale
        dated_at   = options[ :dated_at   ]
        dated_from = options[ :dated_from ]

        endpoint = Hoodoo::Client::Endpoint.endpoint_for(
          resource,
          version,
          {
            :discoverer => @discoverer,
            :session_id => @session_id,
            :locale     => locale,
            :dated_at   => dated_at,
            :dated_from => dated_from
          }
        )

        unless @auto_session_endpoint.nil?
          remote_discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
            :resource         => resource,
            :version          => version,
            :wrapped_endpoint => endpoint
          )

          endpoint = Hoodoo::Client::Endpoint::AutoSession.new(
            resource,
            version,
            :caller_id        => @caller_id,
            :caller_secret    => @caller_secret,
            :session_endpoint => @auto_session_endpoint,
            :discovery_result => remote_discovery_result
          )
        end

        return endpoint
      end

  end
end
