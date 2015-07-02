########################################################################
# File::    interface.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define a class (and some namespace-nested related support
#           classes) that are subclassed by service authors and used to
#           declare the nature of the interface the service implements
#           via a small DSL.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

require 'set'

module Hoodoo; module Services

  # Service implementation authors subclass this to describe the interface that
  # they implement for a particular Resource, as documented in the Loyalty
  # Platform API.
  #
  # See class method ::interface for details.
  #
  class Interface

    ###########################################################################

    # A class containing a series of accessors that describe allowed parameters
    # in a "list" call for a service implementation. The middleware uses this
    # validate incoming query strings for lists and reject requests that ask
    # for unsupported things. When instantiated the class sets itself up with
    # defaults that match those described by the your platform's API. When
    # passed to a Hoodoo::Services::Interface::ToListDSL instance, the DSL
    # methods, if called, update the values stored herein.
    #
    class ToList

      # Limit value; an integer that limits page size in lists.
      #
      attr_reader :limit

      # Sort hash. Keys are supported sort fields, values are arrays of
      # supported sort directions. The first array entry is the default sort
      # order for the sort field.
      #
      attr_reader :sort

      # Default sort key.
      #
      attr_reader :default_sort_key

      # Default sort direction.
      #
      def default_sort_direction
        @sort[ default_sort_key() ][ 0 ]
      end

      # Array of supported search keys as Strings; empty for none defined.
      #
      attr_reader :search

      # Array of supported filter keys as Strings; empty for none defined.
      #
      attr_reader :filter

      # Create an instance with default settings.
      #
      def initialize

        # Remember, these are defaults for the "to_list" object of an
        # interface only. For interface-wide top level defaults, use the
        # embedded calls to the DSL in Interface::interface.

        @limit            = 50
        @sort             = { 'created_at' => Set.new( [ 'desc', 'asc' ] ) }
        @default_sort_key = 'created_at'
        @search           = []
        @filter           = []
      end

      private

        # Private writer - see #limit - but there's a special contract with
        # Hoodoo::Services::Interface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :limit

        # Private writer - see #sort - but there's a special contract with
        # Hoodoo::Services::Interface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :sort

        # Private writer - see #default_sort_key - but there's a special
        # contract with Hoodoo::Services::Interface::ToListDSL which permits it
        # to call here bypassing +private+ via +send()+.
        #
        attr_writer :default_sort_key

        # Private writer - see #search - but there's a special contract with
        # Hoodoo::Services::Interface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :search

        # Private writer - see #filter - but there's a special contract with
        # Hoodoo::Services::Interface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :filter

    end # 'class ToList'

    ###########################################################################

    # Implementation of the DSL that's written inside a block passed to
    # Hoodoo::Services::Interface#to_list. This is an internal implementation
    # class. Instantiate with a Hoodoo::Services::Interface::ToList instance,
    # the data in which is updated as the DSL methods run.
    #
    class ToListDSL

      # Initialize an instance and run the DSL methods.
      #
      # +hoodoo_interface_to_list_instance+:: Instance of
      #                                                  Hoodoo::Services::Interface::ToList
      #                                                  to update with data
      #                                                  from DSL method calls.
      #
      # &block:: Block of code that makes calls to the DSL herein.
      #
      # On exit, the DSL is run and the Hoodoo::Services::Interface::ToList has
      # been updated.
      #
      def initialize( hoodoo_interface_to_list_instance, &block )
        @tl = hoodoo_interface_to_list_instance # Shorthand!

        unless @tl.instance_of?( Hoodoo::Services::Interface::ToList )
          raise "Hoodoo::Services::Interface::ToListDSL\#initialize requires a Hoodoo::Services::Interface::ToList instance - got '#{ @tl.class }'"
        end

        self.instance_eval( &block )
      end

      # Specify the page size (limit) for lists.
      #
      # +limit+:: Page size (integer).
      #
      # Example:
      #
      #     limit 100
      #
      def limit( limit )
        unless limit.is_a?( ::Integer )
          raise "Hoodoo::Services::Interface::ToListDSL\#limit requires an Integer - got '#{ limit.class }'"
        end

        @tl.send( :limit=, limit )
      end

      # Specify extra sort keys and orders that add with whatever platform
      # common defaults are already in place.
      #
      # +sort+:: Hash of sort keys, with values that are an array of supported
      #          sort directions. The first array entry is used as the default
      #          direction if no direction is specified in the client caller's
      #          query string. Use strings or symbols.
      #
      #          To specify that a sort key should be the new default for the
      #          interface in question, wrap it in a call to the #default
      #          DSL method.
      #
      # Example - add sort key '+code+' with directions +:asc+ and +:desc+,
      # plus sort key +:member+ which only supports direction +:asc+.
      #
      #     sort :code   => [ :asc, :desc ],
      #          :member => [ :asc ]
      #
      def sort( sort )
        unless sort.is_a?( ::Hash )
          raise "Hoodoo::Services::Interface::ToListDSL\#sort requires a Hash - got '#{ sort.class }'"
        end

        # Convert Hash keys to Strings and Arrays to Sets of Strings too.

        sort = sort.inject( {} ) do | memo, ( k, v ) |
          memo[ k.to_s ] = Set.new( v.map do | entry |
            entry.to_s
          end )
          memo
        end

        merged = @tl.sort().merge( sort )
        @tl.send( :sort=, merged )
      end

      # Used in conjunction with #sort. Specifies that a sort key should be
      # the default sort order for the interface.
      #
      # Example - add sort key '+code+' with directions +:asc+ and +:desc+,
      # plus sort key +:member+ which only supports direction +:asc+. Say that
      # '+code+' is to be the default sort order.
      #
      #     sort default( :code ) => [ :asc, :desc ],
      #          :member          => [ :asc ]
      #
      def default( sort_key )
        unless sort_key.is_a?( ::String ) || sort_key.is_a?( ::Symbol )
          raise "Hoodoo::Services::Interface::ToListDSL\#default requires a String or Symbol - got '#{ sort_key.class }'"
        end

        @tl.send( :default_sort_key=, sort_key.to_s )
        return sort_key
      end

      # Specify supported search keys in an array. The middleware will make
      # sure the interface implementation is only called with search keys in
      # that list. If a client attempts a search on an unsupported key, their
      # request will be rejected by the middleware.
      #
      # If a service wants to do its own search validation, it should not list
      # call here. Note also that only the keys are specified and validated;
      # value escaping and validation, if necessary, is up to the service
      # implementation.
      #
      # +search+:: Array of permitted search keys, as symbols or strings.
      #            The order of array entries is arbitrary.
      #
      # Example - allow searches specifying +first_name+ and +last_name+ keys:
      #
      #     search :first_name, :last_name
      #
      def search( *search )
        @tl.send( :search=, search.map { | item | item.to_s } )
      end

      # As #search, but for filtering.
      #
      # +filter+:: Array of permitted filter keys, as symbols or strings.
      #            The order of array entries is arbitrary.
      #
      def filter( *filter )
        @tl.send( :filter=, filter.map { | item | item.to_s } )
      end
    end # 'class ToListDSL'

    ###########################################################################

    # Mandatory part of the interface DSL. Declare the interface's URL endpoint
    # and the Hoodoo::Services::Implementation subclass to be invoked when
    # client requests are sent to a URL matching the endpoint.
    #
    # No two interfaces can use the same endpoint within a service application,
    # unless the describe a different interface version - see #version.
    #
    # Example:
    #
    #     endpoint :estimations, PurchaseImplementation
    #
    # +uri_path_fragment+:: Path fragment to match at the start of a URL path,
    #                       as a symbol or string, excluding leading "/". The
    #                       URL path matches the fragment if the path starts
    #                       with a "/", then matches the fragment exactly, then
    #                       is followed by either ".", another "/", or the
    #                       end of the path string. For example, a fragment of
    #                       +:products+ matches all paths out of +/products+,
    #                       +/products.json+ or +/products/22+, but does not
    #                       match +/products_and_things+.
    #
    # +implementation_class+:: The Hoodoo::Services::Implementation subclass
    #                          (the class itself, not an instance of it) that
    #                          should be used when a request matching the
    #                          path fragment is received.
    #
    def endpoint( uri_path_fragment, implementation_class )

      # http://www.ruby-doc.org/core-2.1.3/Module.html#method-i-3C
      #
      unless implementation_class < Hoodoo::Services::Implementation
        raise "Hoodoo::Services::Interface#endpoint must provide Hoodoo::Services::Implementation subclasses, but '#{ implementation_class }' was given instead"
      end

      self.class.send( :endpoint=,       uri_path_fragment    )
      self.class.send( :implementation=, implementation_class )
    end

    # Declare the _major_ version of the interface being implemented. All
    # service endpoints appear at "/v{version}/{endpoint}" relative to whatever
    # root an edge layer defines. If a service interface does not specifiy its
    # version, +1+ is assumed.
    #
    # Two interfaces can exist on the same endpoint provided their versions are
    # different since the resulting route to reach them will be different too.
    #
    # +version+:: Integer major version number, e.g +2+.
    #
    def version( major_version )
      self.class.send( :version=, major_version.to_s.to_i )
    end

    # List the actions that the service implementation supports. If you don't
    # call this, the middleware assumes that all actions are available; else it
    # only calls for supported actions. If you declared an empty array, your
    # implementation would never be called.
    #
    # *supported_actions:: One or more from +:list+, +:show+, +:create+,
    #                      +:update+ and +:delete+. Always use symbols, not
    #                      strings. An exception is raised if unrecognised
    #                      actions are given.
    #
    # Example:
    #
    #     actions :list, :show
    #
    def actions( *supported_actions )
      supported_actions.map! { | item | item.to_sym }
      invalid = supported_actions - Hoodoo::Services::Middleware::ALLOWED_ACTIONS

      unless invalid.empty?
        raise "Hoodoo::Services::Interface#actions does not recognise one or more actions: '#{ invalid.join( ', ' ) }'"
      end

      self.class.send( :actions=, Set.new( supported_actions ) )
    end

    # List any actions which are public - NOT PROTECTED BY SESSIONS. For
    # public actions, no X-Session-ID or similar header is consulted and
    # no session data will be associated with your
    # Hoodoo::Services::Context instance when action methods are called.
    #
    # Use with great care!
    #
    # Note that if the implementation of a public action needs to call
    # other resources, it can only ever call them if those actions in
    # those other resources are also public. The implementation of a
    # public action is prohibited from making calls to protected actions
    # in other resources.
    #
    # *public_actions:: One or more from +:list+, +:show+, +:create+,
    #                   +:update+ and +:delete+. Always use symbols, not
    #                   strings. An exception is raised if unrecognised
    #                   actions are given.
    #
    def public_actions( *public_actions )
      public_actions.map! { | item | item.to_sym }
      invalid = public_actions - Hoodoo::Services::Middleware::ALLOWED_ACTIONS

      unless invalid.empty?
        raise "Hoodoo::Services::Interface#public_actions does not recognise one or more actions: '#{ invalid.join( ', ' ) }'"
      end

      self.class.send( :public_actions=, Set.new( public_actions ) )
    end

    # Set secure log actions.
    #
    # +secure_log_actions+:: A Hash, described below.
    #
    # The given Hash keys are names of actions as Symbols: +:list+,
    # +:show+, +:create+, +:update+ or +:delete+. Values are +:request+,
    # +:response+ or +:both+. For a given action targeted at this resource:
    #
    # * A key of +:request+ means that API call-related Hoodoo automatic
    #   logging will _exclude_ body data for the _inbound request_, but
    #   still include body data in the response. Example: A POST to a Login
    #   resource includes a password which you don't want logged, but the
    #   response data doesn't quote the password back so is "safe". The
    #   secure log actions Hash for the Login resource's interface would
    #   include ":create => :request".
    #
    # * A key of +:response+ means that API call-related Hoodoo automatic
    #   logging will _exclude_ body data for the _outbound response_, but
    #   still include body data in the request. Example: A POST to a
    #   Caller resource creates a Caller with a generated authentication
    #   secret that's only exposed in the POST's response. The inbound
    #   data used to create that Caller can be safely logged, but the
    #   authentication secret is sensitive and shouldn't be recorded. The
    #   secure log actions Hash for the Caller resource's interface would
    #   include ":create => :response".
    #
    #   _ERROR RESPONSES ARE STILL LOGGED_ because that's useful data; so
    #   make sure that if you generate any custom errors in your service
    #   that secure data is not contained within them.
    #
    # * A key of +both+ has the same result as both +:request+ and
    #   +:response+, so body data is never logged. It's hard to come up
    #   with good examples of resources where both the incoming data is
    #   sensitive and the outgoing data is sensitive but the option is
    #   included for competion, as someone out there will need it.
    #
    # Example: The request body data sent by a caller into a resource's
    # +:create+ action will not be logged:
    #
    #     secure_log_for( { :create => :request } )
    #
    # Example: Neither the request data sent by a caller, nor the
    # response data sent back, will be logged for an +:update+ action:
    #
    #     secure_log_for( { :update => :both } )
    #
    # The default is an empty Hash; all actions have both inbound request
    # body data and outbound response body data logged by Hoodoo.
    #
    def secure_log_for( secure_log_actions = {} )
      secure_log_actions = Hoodoo::Utilities.symbolize( secure_log_actions )
      invalid = secure_log_actions.keys - Hoodoo::Services::Middleware::ALLOWED_ACTIONS

      unless invalid.empty?
        raise "Hoodoo::Services::Interface#secure_log_for does not recognise one or more actions: '#{ invalid.join( ', ' ) }'"
      end

      self.class.send( :secure_log_for=, secure_log_actions )
    end

    # An array of supported embed keys (as per documentation, so singular or
    # plural as per resource interface descriptions in the Loyalty Platform
    # API). Things which can be embedded can also be referenced, via the
    # +embed=...+ and +reference=...+ query string entries.
    #
    # The middleware uses the list to reject requests from clients which
    # ask for embedded or referenced entities that were not listed by the
    # interface. If you don't call here, or call here with an empty array,
    # no embedding or referencing will be allowed for calls to the service
    # implementation.
    #
    # +embed+:: Array of permitted embeddable entity names, as symbols or
    #           strings. The order of array entries is arbitrary.
    #
    # Example: An interface permits lists that request embedding or
    # referencing of "vouchers", "balances" and "member":
    #
    #     embed :vouchers, :balances, :member
    #
    # As a result, #embeds would return:
    #
    #     [ 'vouchers', 'balances', 'member' ]
    #
    def embeds( *embeds )
      self.class.send( :embeds=, embeds.map { | item | item.to_s } )
    end

    # Specify parameters related to common index parameters. The block contains
    # calls to the DSL described by Hoodoo::Services::Interface::ToListDSL. The
    # default values should be described by your platform's API - hard-coded at
    # the time of writing as:
    #
    #     limit    50
    #     sort     :created_at => [ :desc, :asc ]
    #     search   nil
    #     filter   nil
    #
    def to_list( &block )
      Hoodoo::Services::Interface::ToListDSL.new(
        self.class.instance_variable_get( '@to_list' ),
        &block
      )
    end

    # Optional description of the JSON parameters (schema) that the interface's
    # implementation requires for calls creating resource instances. The block
    # uses the DSL from Hoodoo::Presenters::Object, so you can specify
    # basic object things like +string+, or higher level things like +type+ or
    # +resource+.
    #
    # If a call comes into the middleware from a client which contains body
    # data that doesn't validate according to your schema, it'll be rejected
    # before even getting as far as your interface implementation.
    #
    # The Hoodoo::Presenters::Object#internationalised DSL method can be
    # called within your block harmlessly, but it has no side effects. Any
    # resource interface that can take internationalised data for creation (or
    # modification) must already have an internationalised representation, so
    # the standard resources in the Hoodoo::Data::Resources collection will
    # already have declared that internationalisation applies.
    #
    # Example 1:
    #
    #     to_create do
    #       string :name, :length => 32, :required => true
    #       text :description
    #     end
    #
    # Example 2: With a resource
    #
    #     to_create do
    #       resource :purchase
    #     end
    #
    # &block:: Block, passed to Hoodoo::Presenters::Object, describing
    #          the fields used for resource creation.
    #
    def to_create( &block )
      obj = Class.new( Hoodoo::Presenters::Base )
      obj.schema( &block )

      self.class.send( :to_create=, obj )
    end

    # As #to_create, but applies when modifying existing resource instances.
    # To avoid repeating yourself, if your modification and creation parameter
    # requirements are identical, call #update_same_as_create.
    #
    # &block:: Block, passed to Hoodoo::Presenters::Object, describing
    #          the fields used for resource modification.
    #
    def to_update( &block )
      obj = Class.new( Hoodoo::Presenters::Base )
      obj.schema( &block )

      self.class.send( :to_update=, obj )
    end

    # Declares that the expected JSON fields described in a #to_create call are
    # the same as those required for modifying resources too.
    #
    # Example:
    #
    #     update_same_as_create
    #
    # ...and that's all. There are no parameters or blocks needed.
    #
    def update_same_as_create
      self.class.send( :to_update=, self.class.to_create )
    end

    # Declares custom errors that are part of this defined interface. This
    # calls directly through to Hoodoo::ErrorDescriptions#errors_for, so
    # see that for details.
    #
    # A service should usually define only a single domain of error using one
    # call to #errors_for, but techncially can make as many calls for as many
    # domains as required. Definitions are merged.
    #
    # +domain+:: Domain, e.g. 'purchase', 'transaction' - see
    #            Hoodoo::ErrorDescriptions#errors_for for details.
    #
    # &block::   Code block making Hoodoo::ErrorDescriptions DSL calls.
    #
    # Example:
    #
    #     errors_for 'transaction' do
    #       error 'duplicate_transaction', status: 409, message: 'Duplicate transaction', :required => [ :client_uid ]
    #     end
    #
    def errors_for( domain, &block )
      descriptions = self.class.errors_for

      if descriptions.nil?
        descriptions = self.class.send( :errors_for=, Hoodoo::ErrorDescriptions.new )
      end

      descriptions.errors_for( domain, &block )
    end

    # Declare additional permissions that you require for a given action.
    #
    # If the implementation of a resource endpoint involves making calls out
    # to other resources, then you need to consider how authorisation is
    # granted to those other resources.
    #
    # The Hoodoo::Services::Session instance for the inbound external caller
    # carries a Hoodoo::Services::Permission instance describing the actions
    # that the caller is permitted to do. The middleware enforces these
    # permissions, so that a resource implementation won't be called at all
    # unless the caller has permission to do so.
    #
    # These permissions continue to apply during inter-resource calls. The
    # wider session context is always applied. So, if one resource calls
    # another resource, either:
    #
    # * The inbound API caller's session must have all necessary permissions
    #   for both the resource it is actually directly calling, and for any
    #   actions in any resources that the called resource in turn calls (and
    #   so-on, for any chain of resources).
    #
    # ...or...
    #
    # * The resource uses this +additional_permissions_for+ method to declare
    #   up-front that it will require the described permissions when a
    #   particular action is performed on it. When an inter-resource call is
    #   made, a temporary internal-only session is constructed that merges
    #   the permissions of the inbound caller with the additional permissions
    #   requested by the resource. The downstream called resource needs no
    #   special case code at all - it just sees a valid session with valid
    #   permissions and does what the upstream resource asked of it.
    #
    # For example, suppose a resource Clock returns both a time and a date,
    # by calling out to the Time and Date resources. One option is that the
    # inbound caller must have +show+ action permissions for all of Clock,
    # Time and Date; if any of those are missing, then an attempt to call
    # +show+ on the Clock resource would result in a 403 response.
    #
    # The other option is for Clock's interface to declare its requirements:
    #
    #     additional_permissions_for( :show ) do | p |
    #       p.set_resource( :Time, :show, Hoodoo::Services::Permissions::ALLOW )
    #       p.set_resource( :Date, :show, Hoodoo::Services::Permissions::ALLOW )
    #     end
    #
    # Suppose you could create Clock instances for some reason, but there
    # was an audit trail for this; Clock must create an Audit entry itself,
    # but you don't want to expose this ability to external callers through
    # their session permissions; so, just declare your additional
    # permissions for that specific inter-service case:
    #
    #     additional_permissions_for( :create ) do | p |
    #       p.set_resource( :Audit, :create, Hoodoo::Services::Permissions::ALLOW )
    #     end
    #
    # The call says which action in _the declaring interface's resource_ is
    # a target. The block takes a single parameter; this is a default
    # initialisation Hoodoo::Services::Permissions instance. Use that
    # object's methods to set up whatever permissions you need in other
    # resources, to successfully process the action in question. You only
    # need to describe the resources you immediately call, not the whole
    # chain - if "this" resource calls another, then it's up to the other
    # resource to in turn describe additional permissions should it make its
    # own set of downstream calls to further resource endpoints.
    #
    # Setting default permissions or especially the default permission
    # fallback inside the block is possible but *VERY STRONGLY DISCOURAGED*.
    # Instead, precisely describe the downstream resources, actions and
    # permissions that are required.
    #
    # Note an important restriction - public actions (see ::public_actions)
    # cannot be augmented in this way. A public action in one resource can
    # only ever call public actions in other resources. This is because no
    # session is needed _at all_ to call a public action; calling into a
    # protected action in another resource from this context would require
    # invention of a full caller context which would be entirely invented
    # and could represent an accidental (and significant) security hole.
    #
    # If you call this method for the same action more than once, the last
    # call will be the one that takes effect - each call overwrites the
    # results of any previous call made for the same action.
    #
    # Parameters are:
    #
    # +action+:: The action in this interface which will require the
    #            additional permissions to be described. Pass a Symbol or
    #            equivalent String from the list in
    #            Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
    #
    # &block::   Block which is passed a new, default state
    #            Hoodoo::Services::Permissions instance; make method calls
    #            on this instance to describe the required permissions.
    #
    def additional_permissions_for( action, &block )
      action = action.to_s

      unless block_given?
        raise 'Hoodoo::Services::Interface#additional_permissions_for must be passed a block'
      end

      p = Hoodoo::Services::Permissions.new
      yield( p )

      additional_permissions = self.class.additional_permissions() || {}
      additional_permissions[ action ] = p
      self.class.send( :additional_permissions=, additional_permissions )
    end

  protected

    # Define the subclass Service's interface. A DSL is used with methods
    # documented in the Hoodoo::Services::InterfaceDSL class.
    #
    # The absolute bare minimum interface description just states that a
    # particular implementation class is used when requests are made to a
    # particular URL endpoint, which is implementing an interface for a
    # particular given resource. For a hypothetical Magic resource interface:
    #
    #     class MagicImplementation < Hoodoo::Services::Implementation
    #       # ...implementation code goes here...
    #     end
    #
    #     class MagicInterface < Hoodoo::Services::Interface
    #       interface :Magic do
    #         endpoint :paul_daniels, MagicImplementation
    #       end
    #     end
    #
    # This would cause all calls to URLs at '/paul_daniels[...]' to be routed to
    # an instance of the MagicImplementation class.
    #
    # Addtional DSL facilities allow the interface to say what HTTP methods
    # it supports (in terms of the action methods that it supports inside its
    # implementation class), describe any extra sort, search or filter data it
    # allows beyond the common fields and describe the expected JSON fields for
    # creation and/or modification actions. By specifing these, the service
    # middleware code is able to do extra validation and sanitisation of client
    # requests, but they're entirely optional if the implementation class wants
    # to take over all of that itself.
    #
    # +resource+:: Name of the resource that the interface is for, as a String
    #              or Symbol (e.g. +:Purchase+).
    #
    # &block::     Block that calls the Hoodoo::Services::InterfaceDSL methods;
    #              #endpoint is the only mandatory call.
    #
    def self.interface( resource, &block )

      if @to_list.nil?
        @to_list = Hoodoo::Services::Interface::ToList.new
      else
        raise "Hoodoo::Services::Interface subclass unexpectedly ran ::interface more than once"
      end

      self.resource = resource.to_sym

      interface = self.new
      interface.instance_eval do
        version 1
        embeds # Nothing
        actions *Hoodoo::Services::Middleware::ALLOWED_ACTIONS
        public_actions # None
        secure_log_for # None
      end

      interface.instance_eval( &block )

      if self.endpoint.nil?
        raise "Hoodoo::Services::Interface subclasses must always call the 'endpoint' DSL method in their interface descriptions"
      end

    end

    # Define various class instance variable (sic.) accessors.
    #
    # * Instance variable: things set on individual "Foo" instances ("Foo.new")
    # * Class instance variables: things set on the "Foo" class only
    # * Class variables: things set on the "Foo" class *and all subclasses*
    #
    class << self

      public

        # Endpoint path as declared by service, without preceding "/", possibly
        # as a symbol - e.g. +:products+ for "/products[...]" as an implied
        # endpoint.
        #
        attr_reader :endpoint

        # Major version of interface as an integer. All service endpoint routes
        # have "v{version}/" as a prefix, e.g. "/v1/products[...]".
        #
        attr_reader :version

        # Name of the resource the interface addresses as a symbol, e.g.
        # +:Product+.
        #
        attr_reader :resource

        # Implementation class for the service. An
        # Hoodoo::Services::Implementation subclass - the class, not an
        # instance of it.
        #
        attr_reader :implementation

        # Supported action methods as a Set of symbols with one or more of
        # +:list+, +:show+, +:create+, +:update+ or +:delete+. The presence of
        # a Symbol indicates a supported action. If empty, no actions are
        # supported. The default is for all actions to be present in the Set.
        #
        attr_reader :actions

        # Public action methods as a Set of symbols with one or more of
        # +:list+, +:show+, +:create+, +:update+ or +:delete+. The presence
        # of a Symbol indicates an action open to the public and not subject
        # to session security. If empty, all actions are protected by session
        # security. The default is an empty Set.
        #
        attr_reader :public_actions

        # Secure log actions set by #secure_log_for - see that call for
        # details. The default is an empty Hash.
        #
        attr_reader :secure_log_for

        # Array of strings listing allowed embeddable things. Each string
        # matches the split up comma-separated value for query string
        # "_embed" or "_reference" keys. For example:
        #
        #     ...&_embed=foo,bar
        #
        # ...would be valid provided there was an embedding declaration
        # such as:
        #
        #     embeds :foo, :bar
        #
        # ...which would in turn lead this accessor to return:
        #
        #     [ 'foo', 'bar' ]
        #
        attr_reader :embeds

        # A Hoodoo::Services::Interface::ToList instance describing the list
        # parameters for the interface as a Set of Strings. See also
        # Hoodoo::Services::Interface::ToListDSL.
        #
        def to_list
          @to_list ||= Hoodoo::Services::Interface::ToList.new
          @to_list
        end

        # A Hoodoo::Presenters::Object instance describing the schema
        # for client JSON coming in for calls that create instances of the
        # resource that the service's interface is addressing. If +nil+,
        # arbitrary data is acceptable (the implementation becomes entirely
        # responsible for data validation).
        #
        attr_reader :to_create

        # A Hoodoo::Presenters::Object instance describing the schema
        # for client JSON coming in for calls that modify instances of the
        # resource that the service's interface is addressing. If +nil+,
        # arbitrary data is acceptable (the implementation becomes entirely
        # responsible for data validation).
        #
        attr_reader :to_update

        # A Hoodoo::ErrorDescriptions instance describing all errors that
        # the interface might return, including the default set of platform
        # and generic errors. If nil, there are no additional error codes
        # beyond the default set.
        #
        attr_reader :errors_for

        # A Hash, keyed by String equivalents of the Symbols in
        # Hoodoo::Services::Middleware::ALLOWED_ACTIONS, where the values
        # are Hoodoo::Services::Permissions instances describing extended
        # permissions for the related action. See
        # ::additional_permissions_for.
        #
        attr_reader :additional_permissions

      private

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::endpoint.
        #
        attr_writer :endpoint

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::version.
        #
        attr_writer :version

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::resource.
        #
        attr_writer :resource

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::implementation.
        #
        attr_writer :implementation

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::actions.
        #
        attr_writer :actions

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::public_actions.
        #
        attr_writer :public_actions

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::secure_log_for.
        #
        attr_writer :secure_log_for

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::embeds.
        #
        attr_writer :embeds

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::to_create.
        #
        attr_writer :to_create

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::to_update.
        #
        attr_writer :to_update

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::errors_for.
        #
        attr_writer :errors_for

        # Private property writer allows instances running the DSL to set
        # values on the class for querying using the public readers.
        # See ::additional_permissions.
        #
        attr_writer :additional_permissions

    end  # 'class << self'
  end    # 'class Interface'

end; end # 'module Hoodoo; module Services'
