########################################################################
# File::    error_descriptions.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Error descriptions - provide a DSL and a container for a
#           list of known error codes and associated data. Includes the
#           Loyalty Platform API +platform+ and +generic+ domain codes
#           by default. Services can declare additional errors.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
#           09-Oct-2014 (ADH): Updated for Preview Release 8.
#           16-Oct-2014 (TC):  Added session error
########################################################################

module ApiTools

  # A collection of error descriptions. API service implementations create one
  # of these, which self-declares platform and generic error domain codes. A
  # simple DSL is available to declare service-specific errors. Since the
  # middleware is responsible for instantiating an error collection inside a
  # response object which service implementations use to signal error
  # conditions, the service's _interface_ class uses the interface description
  # DSL to call through to here behind the scenes; for example:
  #
  #     class TransactionImplementation < ApiTools::ServiceImplementation
  #       # ...
  #     end
  #
  #     class TransactionInterface < ApiTools::ServiceInterface
  #       interface :Transaction do
  #         endpoint :transactions, TransactionImplementation
  #         errors_for 'transaction' do
  #           error 'duplicate_transaction', status: 409, message: 'Duplicate transaction', :required => [ :client_uid ]
  #         end
  #       end
  #     end
  #
  # The #errors_for method takes the domain of the error as a string - the
  # part that comes before the "+.+" in error codes. Then a series of +error+
  # calls describe the individual error codes. See
  # ApiTools::ErrorDescriptions::DomainDescriptions#error for details.
  #
  # An instance of the ApiTools::ErrorDescriptions class gets built behind
  # the scenes as part of the service interface description. This is found by
  # the middleware and passed to an ApiTools::Errors constructor. The result
  # is stored in an ApiTools::ServiceResponse instance and passed to handler
  # methods in the service's ApiTools::ServiceImplementation subclass for each
  # request. Service implementations access the errors collection through
  # ApiTools::ServiceResponse#errors and can then add errors using the generic
  # or platform domains, or whatever additional custom domain(s) they defined
  # in the service interface subclass.
  #
  # For direct callers (e.g. the middleware), there is a shorthand form to
  # invoke the DSL where the constructor is used in the same way as
  # #errors_for:
  #
  #     ERROR_DESCRIPTIONS = ApiTools::ErrorDescriptions.new( 'transaction' ) do
  #       error 'duplicate_transaction', status: 409, message: 'Duplicate transaction', :required => [ :client_uid ]
  #     end
  #
  # Either way,
  #
  # As per the example above, services can share an instance across requests
  # (and threads) via a class's variable if the descriptions don't change. You
  # would use the descriptions to inform an ApiTools::Errors instance of the
  # available codes and their requirements:
  #
  #    @errors = ApiTools::Errors.new( ERROR_DESCRIPTIONS )
  #
  class ErrorDescriptions

    # Create an instance, self-declaring +platform+ and +generic+ domain
    # errors. You can optionally call the constructor with an error domain
    # and code block, to declare errors all in one go rather than making a
    # separate call to #errors_for (but both approaches are valid).
    #
    # +domain+:: Optional domain, just as used in #errors_for
    # &block:: Optional block, just as used in #errors_for
    #
    def initialize( domain = nil, &block )

      @descriptions = {}

      # Up to date at Preview Release 9, 2014-11-06.

      errors_for 'platform' do
        error 'not_found',              status: 404, message: 'Not found',                    reference: [ :entity_name ]
        error 'method_not_allowed',     status: 422, message: 'Method not allowed'
        error 'malformed',              status: 422, message: 'Malformed request'
        error 'invalid_session',        status: 401, message: 'Invalid session'
        error 'forbidden',              status: 403, message: 'Action not authorized'
        error 'fault',                  status: 500, message: 'Internal error',               reference: [ :exception ]
      end

      # Up to date at Preview Release 9, 2014-11-06.

      errors_for 'generic' do
        error 'not_found',              status: 404, message: 'Resource not found',           reference: [ :ident ]
        error 'malformed',              status: 422, message: 'Malformed payload'
        error 'required_field_missing', status: 422, message: 'Required field missing',       reference: [ :field_name ]
        error 'invalid_string',         status: 422, message: 'Invalid string format',        reference: [ :field_name ]
        error 'invalid_integer',        status: 422, message: 'Invalid integer format',       reference: [ :field_name ]
        error 'invalid_float',          status: 422, message: 'Invalid float format',         reference: [ :field_name ]
        error 'invalid_decimal',        status: 422, message: 'Invalid decimal format',       reference: [ :field_name ]
        error 'invalid_boolean',        status: 422, message: 'Invalid boolean format',       reference: [ :field_name ]
        error 'invalid_enum',           status: 422, message: 'Invalid enumeration',          reference: [ :field_name ]
        error 'invalid_date',           status: 422, message: 'Invalid date specifier',       reference: [ :field_name ]
        error 'invalid_time',           status: 422, message: 'Invalid time specifier',       reference: [ :field_name ]
        error 'invalid_datetime',       status: 422, message: 'Invalid date-time specifier',  reference: [ :field_name ]
        error 'invalid_uuid',           status: 422, message: 'Invalid UUID',                 reference: [ :field_name ]
        error 'invalid_array',          status: 422, message: 'Invalid array',                reference: [ :field_name ]
        error 'invalid_object',         status: 422, message: 'Invalid object',               reference: [ :field_name ]
        error 'invalid_hash',           status: 422, message: 'Invalid hash',                 reference: [ :field_name ]
        error 'invalid_duplication',    status: 422, message: 'Duplicates not allowed',       reference: [ :field_name ]
        error 'invalid_state',          status: 422, message: 'State transition not allowed', reference: [ :destination_state ]
        error 'invalid_parameters',     status: 422, message: 'Invalid parameters'
      end

      # Add caller's custom errors for the shorthand form, if provided.

      if ( domain != nil && domain != '' && block_given?() )
        errors_for( domain, &block )
      end
    end

    # Implement the collection's part of the small DSL used for error
    # declaration. Call here, passing the error domain (usually the singular
    # service name or resource name, e.g. "+transaction+" and defined by the
    # part of the Platform API the service is implementing) and a block. The
    # block makes one or more "+error+" calls, which actually end up calling
    # ApiTools::ErrorDescriptions::DomainDescriptions#error behind the scenes.
    #
    # See the implementation of #initialize for a worked example.
    #
    # +domain+:: Error domain, e.g. +platform+, +transaction+
    # &block:: Block which makes one or more calls to "+error+"
    #
    def errors_for( domain, &block )
      domain_descriptions = ApiTools::ErrorDescriptions::DomainDescriptions.new( domain )
      domain_descriptions.instance_eval( &block )

      @descriptions.merge!( domain_descriptions.descriptions )
    end

    # Is the given error code recognised? Returns +true+ if so, else +false+.
    #
    # +code+:: Error code in full, e.g. +generic.invalid_state'.
    #
    def recognised?( code )
      @descriptions.has_key?( code )
    end

    # Return the options description hash, as passed to +error+ calls in the
    # block given to #errors_for, for the given code.
    #
    # +code+:: Error code in full, e.g. +generic.invalid_state'.
    #
    def describe( code )
      @descriptions[ code ]
    end

    # Contain a description of errors for a particular domain, where the domain
    # is a grouping string such as "platform", "generic", or a short service
    # name. Usually driven via ApiTools::ErrorDescriptions, not directly.
    #
    class DomainDescriptions

      # Domain name for this description instance (string).
      #
      attr_reader( :domain )

      # Hash of all descriptions, keyed by full error code, with options
      # hash data as values (see #error for details).
      #
      attr_reader( :descriptions )

      # Initialize a new instance for the given domain.
      #
      # +domain+:: The domain string - for most service-based callers, usually
      #            a short service name like +members+ or +transactions+.
      #
      def initialize( domain )
        @domain       = domain
        @descriptions = {}
      end

      # Describe an error.
      #
      # +name+::    The error name - the bit after the "+.+" in the code, e.g.
      #             +invalid_parameters+.
      #
      # +options+:: Options hash. See below.
      #
      # The options hash contains symbol keys named as follows, with values as
      # described:
      #
      # +:status+::    The integer or string HTTP status code to be associated
      #                with this error
      #
      # +'message'+::   The +en-nz+ language human-readable error message used
      #                for developers.
      #
      # +'reference'+:: Optional array of required named references. When errors
      #                are added (via ApiTools::Errors#add_error) to a
      #                collection, required reference(s) from this array must
      #                be provided by the error-adding caller else an exception
      #                will be raised. This ensures correct, fully qualified
      #                error data is logged and sent to clients.
      #
      def error( name, options )
        options       = ApiTools::Utilities.stringify( options )
        required_keys = [ 'status', 'message' ]

        reference              = options[ 'reference' ]
        options[ 'reference' ] = reference.map( &:to_s ) if reference.is_a?( Array )

        required_keys.each do | required_key |
          unless options.has_key?( required_key )
            raise "Error description options hash missing required key '#{ required_key }'"
          end
        end

        @descriptions[ "#{ @domain }.#{ name }" ] = options
      end
    end
  end
end
