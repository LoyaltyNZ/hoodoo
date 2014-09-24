module ApiTools

  # Service implementation authors subclass this to describe the interface that
  # they implement for a particular Resource, as documented in the Loyalty
  # Platform API.
  #
  # A DSL is used to describe the interface. The absolute bare minimum just
  # says that a particular implementation class is used when requests are made
  # to a particular URL endpoint. For a hypothetical Magic resource interface:
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
  # it supports (in terms of the action methods that it expects to be called in
  # its implementation class), describe any extra sort, search or filter data
  # it allows beyond the common fields and describe the expected JSON fields
  # for creation and/or modification actions. By specifing these, the service
  # middleware code is able to do extra validation and sanitisation of client
  # requests, but they're entirely optional if the implementation class wants
  # to take over all of that itself.
  #
  class ServiceInterface

    # Endpoint path as declared by service, without preceding "/", possibly as
    # a symbol - e.g. +:products+ for "/products[...]" as an implied endpoint.
    #
    attr_reader :the_endpoint

    # Implementation class for the service. An ApiTools::ServiceImplementation
    # subclass.
    #
    attr_reader :the_implementation

    # Supported action methods as a list of symbols, with one or more of
    # +:list+, +:show+, +:create+, +:update+ or +:delete+. If +nil+, assume
    # all actions are supported.
    #
    attr_reader :the_actions

    #
    attr_reader :the_list_extensions

    # An ApiTools::Data::DocumentedObject instance describing the schema for
    # client JSON coming in for calls that create instances of the resource
    # that the service's interface is addressing. If +nil+, arbitrary data is
    # acceptable (the implementation becomes entirely responsible for data
    # validation).
    #
    attr_reader :the_creation_schema

    # An ApiTools::Data::DocumentedObject instance describing the schema for
    # client JSON coming in for calls that modify instances of the resource
    # that the service's interface is addressing. If +nil+, arbitrary data is
    # acceptable (the implementation becomes entirely responsible for data
    # validation).
    #
    attr_reader :the_modification_schema

    # A fully initialised instance of this class, or +nil+ if there has been
    # no interface definition made (yet).
    #
    def self.interface
      @interface
    end

  protected

    # Subclasses call here to define their interface. See the documentation for
    # the wider ApiTools::ServiceInterface class for details.
    #
    # +&block+:: Block that calls the ApiTools::ServiceInterface DSL; #endpoint
    #            is the only mandatory call.
    #
    def self.interface( &block )
      @interface = self.new
      @interface.instance_eval( &block )

      if @endpoint.nil?
        raise "ApiTools::ServiceInterface subclasses must always call the 'endpoint' DSL method in their interface descriptions"
      end
    end

    # Mandatory part of the interface DSL. Declare the interface's URL endpoint
    # and the ApiTools::ServiceImplementation subclass to be invoked when
    # client requests are sent to a URL matching the endpoint.
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
    #                       match +/products_and_things[...]+.
    #
    # +implementation_class+:: The ApiTools::ServiceImplementation subclass
    #                          (the class itself, not an instance of it) that
    #                          should be used when a request matching the
    #                          path fragment is received.
    #
    def endpoint( uri_path_fragment, implementation_class )
      unless implementation_class.is_a?( ApiTools::ServiceImplementation )
        raise "ApiTools::ServiceInterface#endpoint must provide ApiTools::ServiceImplementation subclasses - #{ implementation_class.class } was given instead"
      end

      @the_endpoint       = uri_path_fragment
      @the_implementation = implementation_class
    end

    # List the actions that the service implementation supports. If you don't
    # call this, the middleware assumes that all actions are available; else it
    # only calls for supported actions. If you declared an empty array, your
    # implementation would never be called.
    #
    # +*supported_actions+:: One or more from +:list+, +:show+, +:create+,
    #                        +:update+ and +:delete+. Always use symbols, not
    #                        strings. An exception is raised if unrecognised
    #                        actions are given.
    #
    # Example:
    #
    #     actions :list, :show
    #
    def actions( *supported_actions )
      invalid = supported_actions - ApiTools::ServiceMiddleware::ALLOWED_ACTIONS

      unless invalid.empty?
        raise "ApiTools::ServiceInterface#actions does not recognise one or more actions: '#{ invalid }'"
      end

      @the_actions = supported_actions
    end

    # Specify parameters related to common index parameters.

    def to_list( &block )
      @the_list_extensions = nil # TODO
    end

    # Optional description of the JSON parameters (schema) that the interface's
    # implementation requires for calls creating resource instances. The block
    # uses the DSL from ApiTools::Data::DocumentedKind, so you can specify
    # basic object things like +string+, or higher level things like +type+.
    #
    # If a call comes into the middleware from a client which contains body
    # data that doesn't validate according to your schema, it'll be rejected
    # before even getting as far as your interface implementation.
    #
    # The ApiTools::Data::DocumentedKind#internationalised DSL method can be
    # called within your block harmlessly, but it has no side effects. Any
    # resource interface that can take internationalised data for creation (or
    # modification) must already have an internationalised representation, so
    # the standard resources in the ApiTools::Data::Resources collection will
    # already have declared that internationalisation applies.
    #
    # Example:
    #
    #     to_create do
    #       string :name, :length => 32, :required => true
    #       text :description
    #     end
    #
    # +&block+:: Block, passed to ApiTools::Data::DocumentedKind, describing
    #            the fields used for resource creation.
    #
    def to_create( &block )
      @the_creation_schema = ApiTools::Data::DocumentedObject.new
      @the_creation_schema.instance_eval( &block )
    end

    # As #to_create, but applies when modifying existing resource instances.
    # To avoid repeating yourself, if your modification and creation parameter
    # requirements are identical, call #update_same_as_create.
    #
    # +&block+:: Block, passed to ApiTools::Data::DocumentedKind, describing
    #            the fields used for resource modification.
    #
    def to_update( &block )
      @the_modification_schema = ApiTools::Data::DocumentedObject.new
      @the_modification_schema.instance_eval( &block )
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
      @the_modification_schema = @the_creation_schema
    end
  end
end
