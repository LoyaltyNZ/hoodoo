########################################################################
# File::    service_interface.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define a class (and some namespace-nested related support
#           classes) that are subclassed by service authors and used to
#           declare the nature of the interface the service implements
#           via a small DSL.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # Service implementation authors subclass this to describe the interface that
  # they implement for a particular Resource, as documented in the Loyalty
  # Platform API.
  #
  # See class method ::interface for details.
  #
  class ServiceInterface

    ###########################################################################

    # A class containing a series of accessors that describe allowed parameters
    # in a "list" call for a service implementation. The middleware uses this
    # validate incoming query strings for lists and reject requests that ask
    # for unsupported things. When instantiated the class sets itself up with
    # defaults that match those described by the Loyalty Platform API. When
    # passed to an ApiTools::ServiceInterface::ToListDSL instance, the DSL
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

      # Array of supported search keys; empty for none defined.
      #
      attr_reader :search

      # Array of supported filter keys; empty for none defined.
      #
      attr_reader :filter

      # Create an instance with default settings.
      #
      def initialize
        @limit            = 50
        @sort             = { 'created_at' => [ 'desc', 'asc' ] }
        @default_sort_key = 'created_at'
        @search           = []
        @filter           = []
      end

      private

        # Private writer - see #limit - but there's a special contract with
        # ApiTools::ServiceInterface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :limit

        # Private writer - see #sort - but there's a special contract with
        # ApiTools::ServiceInterface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :sort

        # Private writer - see #default_sort_key - but there's a special
        # contract with ApiTools::ServiceInterface::ToListDSL which permits it
        # to call here bypassing +private+ via +send()+.
        #
        attr_writer :default_sort_key

        # Private writer - see #search - but there's a special contract with
        # ApiTools::ServiceInterface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :search

        # Private writer - see #filter - but there's a special contract with
        # ApiTools::ServiceInterface::ToListDSL which permits it to call here
        # bypassing +private+ via +send()+.
        #
        attr_writer :filter

    end # 'class ToList'

    ###########################################################################

    # Implementation of the DSL that's written inside a block passed to
    # ApiTools::ServiceInterface#to_list. This is an internal implementation
    # class. Instantiate with an ApiTools::ServiceInterface::ToList instance,
    # the data in which is updated as the DSL methods run.
    #
    class ToListDSL

      # Initialize an instance and run the DSL methods.
      #
      # +api_tools_service_interface_to_list_instance+:: Instance of
      #          ApiTools::ServiceInterface::ToList to update with data from
      #          DSL method calls.
      #
      # &block:: Block of code that makes calls to the DSL herein.
      #
      # On exit, the DSL is run and the ApiTools::ServiceInterface::ToList has
      # been updated.
      #
      def initialize( api_tools_service_interface_to_list_instance, &block )
        @tl = api_tools_service_interface_to_list_instance # Shorthand!

        unless @tl.instance_of?( ApiTools::ServiceInterface::ToList )
          raise "ApiTools::ServiceInstance::ToListDSL\#initialize requires an ApiTools::ServiceInstance::ToList instance - got '#{ @tl.class }'"
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
          raise "ApiTools::ServiceInstance::ToListDSL\#limit requires an Integer - got '#{ limit.class }'"
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
      # Example - add sort key +'code'+ with directions +:asc+ and +:desc+,
      # plus sort key +:member+ which only supports direction +:asc+.
      #
      #     sort 'code'   => [ :asc, :desc ],
      #          :member => [ :asc ]
      #
      def sort( sort )
        unless sort.is_a?( ::Hash )
          raise "ApiTools::ServiceInstance::ToListDSL\#sort requires a Hash - got '#{ sort.class }'"
        end

        # Convert hash keys to strings and values in arrays to strings too.

        sort = sort.inject( {} ) do | memo, (k, v ) |
          memo[ k.to_s ] = v.map do | entry |
            entry.to_s
          end
          memo
        end

        merged = @tl.sort().merge( sort )
        @tl.send( :sort=, merged )
      end

      # Used in conjunction with #sort. Specifies that a sort key should be
      # the default sort order for the interface.
      #
      # Example - add sort key +'code'+ with directions +:asc+ and +:desc+,
      # plus sort key +:member+ which only supports direction +:asc+. Say that
      # +'code'+ is to be the default sort order.
      #
      #     sort default( 'code' ) => [ :asc, :desc ],
      #          :member          => [ :asc ]
      #
      def default( sort_key )
        unless sort_key.is_a?( ::String ) || sort_key.is_a?( ::Symbol )
          raise "ApiTools::ServiceInstance::ToListDSL\#default requires a String or Symbol - got '#{ sort_key.class }'"
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
    # and the ApiTools::ServiceImplementation subclass to be invoked when
    # client requests are sent to a URL matching the endpoint.
    #
    # No two interfaces can use the same endpoint within a service application,
    # unless the describe a different interface version - see #version.
    #
    # Example:
    #
    #     endpoint :estimations, PurchaseServiceImplementation
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
    # +implementation_class+:: The ApiTools::ServiceImplementation subclass
    #                          (the class itself, not an instance of it) that
    #                          should be used when a request matching the
    #                          path fragment is received.
    #
    def endpoint( uri_path_fragment, implementation_class )

      # http://www.ruby-doc.org/core-2.1.3/Module.html#method-i-3C
      #
      unless implementation_class < ApiTools::ServiceImplementation
        raise "ApiTools::ServiceInterface#endpoint must provide ApiTools::ServiceImplementation subclasses, but '#{ implementation_class }' was given instead"
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
      invalid = supported_actions - ApiTools::ServiceMiddleware::ALLOWED_ACTIONS

      unless invalid.empty?
        raise "ApiTools::ServiceInterface#actions does not recognise one or more actions: '#{ invalid.join( ', ' ) }'"
      end

      self.class.send( :actions=, supported_actions )
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
    # calls to the DSL described by ApiTools::ServiceInterface::ToListDSL. The
    # default values are described in the Loyalty Platform API - at the time of
    # writing:
    #
    #     limit    50
    #     sort     :created_at => [ :desc, :asc ]
    #     search   nil
    #     filter   nil
    #
    def to_list( &block )
      ApiTools::ServiceInterface::ToListDSL.new(
        self.class.instance_variable_get( '@to_list' ),
        &block
      )
    end

    # Optional description of the JSON parameters (schema) that the interface's
    # implementation requires for calls creating resource instances. The block
    # uses the DSL from ApiTools::Data::DocumentedObject, so you can specify
    # basic object things like +string+, or higher level things like +type+ or
    # +resource+.
    #
    # If a call comes into the middleware from a client which contains body
    # data that doesn't validate according to your schema, it'll be rejected
    # before even getting as far as your interface implementation.
    #
    # The ApiTools::Data::DocumentedObject#internationalised DSL method can be
    # called within your block harmlessly, but it has no side effects. Any
    # resource interface that can take internationalised data for creation (or
    # modification) must already have an internationalised representation, so
    # the standard resources in the ApiTools::Data::Resources collection will
    # already have declared that internationalisation applies.
    #
    # Example 1:
    #
    #     to_create do
    #       string :name, :length => 32, :required => true
    #       text :description
    #     end
    #
    # Example 2 with a resource
    #
    #     to_create do
    #       resource :purchase
    #     end
    #
    # &block:: Block, passed to ApiTools::Data::DocumentedObject, describing
    #          the fields used for resource creation.
    #
    def to_create( &block )
      obj = ApiTools::Data::DocumentedObject.new
      obj.instance_eval( &block )

      self.class.send( :to_create=, obj )
    end

    # As #to_create, but applies when modifying existing resource instances.
    # To avoid repeating yourself, if your modification and creation parameter
    # requirements are identical, call #update_same_as_create.
    #
    # &block:: Block, passed to ApiTools::Data::DocumentedObject, describing
    #          the fields used for resource modification.
    #
    def to_update( &block )
      obj = ApiTools::Data::DocumentedObject.new
      obj.instance_eval( &block )

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
    # calls directly through to ApiTools::ErrorDescriptions#errors_for, so
    # see that for details.
    #
    # A service should usually define only a single domain of error using one
    # call to #errors_for, but techncially can make as many calls for as many
    # domains as required. Definitions are merged.
    #
    # +domain+:: Domain, e.g. 'purchase', 'transaction' - see
    #            ApiTools::ErrorDescriptions#errors_for for details.
    #
    # &block::   Code block making ApiTools::ErrorDescriptions DSL calls.
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
        descriptions = self.class.send( :errors_for=, ApiTools::ErrorDescriptions.new )
      end

      descriptions.errors_for( domain, &block )
    end

  protected

    # Define the subclass service's interface. A DSL is used with methods
    # documented in the ApiTools::ServiceInterfaceDSL class.
    #
    # The absolute bare minimum interface description just states that a
    # particular implementation class is used when requests are made to a
    # particular URL endpoint, which is implementing an interface for a
    # particular given resource. For a hypothetical Magic resource interface:
    #
    #     class MagicServiceImplementation < ApiTools::ServiceImplementation
    #       # ...implementation code goes here...
    #     end
    #
    #     class MagicServiceInterface < ApiTools::ServiceInterface
    #       interface :Magic do
    #         endpoint :paul_daniels, MagicServiceImplementation
    #       end
    #     end
    #
    # This would cause all calls to URLs at '/paul_daniels[...]' to be routed to
    # an instance of the MagicServiceImplementation class.
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
    # +resource+:: Name of the resource that the interface is for, as a symbol;
    #              for example, ':Purchase'.
    # &block::     Block that calls the ApiTools::ServiceInterfaceDSL methods;
    #              #endpoint is the only mandatory call.
    #
    def self.interface( resource, &block )
      self.resource = resource.to_sym

      raise "ApiTools::ServiceInterface subclass unexpectedly ran ::interface more than once" unless @to_list.nil?

      @to_list = ApiTools::ServiceInterface::ToList.new

      interface = self.new
      interface.instance_eval do
        version 1
      end
      interface.instance_eval( &block )

      if self.endpoint.nil?
        raise "ApiTools::ServiceInterface subclasses must always call the 'endpoint' DSL method in their interface descriptions"
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
        # ApiTools::ServiceImplementation subclass - the class, not an
        # instance of it.
        #
        attr_reader :implementation

        # Supported action methods as a list of symbols, with one or more of
        # +:list+, +:show+, +:create+, +:update+ or +:delete+. If +nil+, assume
        # all actions are supported.
        #
        attr_reader :actions

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

        # An ApiTools::ServiceInterface::ToList instance describing the list
        # parameters for the interface. See also
        # ApiTools::ServiceInterface::ToListDSL.
        #
        def to_list
          @to_list ||= ApiTools::ServiceInterface::ToList.new
          @to_list
        end

        # An ApiTools::Data::DocumentedObject instance describing the schema
        # for client JSON coming in for calls that create instances of the
        # resource that the service's interface is addressing. If +nil+,
        # arbitrary data is acceptable (the implementation becomes entirely
        # responsible for data validation).
        #
        attr_reader :to_create

        # An ApiTools::Data::DocumentedObject instance describing the schema
        # for client JSON coming in for calls that modify instances of the
        # resource that the service's interface is addressing. If +nil+,
        # arbitrary data is acceptable (the implementation becomes entirely
        # responsible for data validation).
        #
        attr_reader :to_update

        # An ApiTools::ErrorDescriptions instance describing all errors that
        # the interface might return, including the default set of platform
        # and generic errors. If nil, there are no additional error codes
        # beyond the default set.
        #
        attr_reader :errors_for

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

    end # 'class << self'
  end   # 'class ServiceInterface'
end     # 'module ApiTools'
