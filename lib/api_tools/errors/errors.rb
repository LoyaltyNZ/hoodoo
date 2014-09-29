########################################################################
# File::    errors.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A collection of error messages, starting empty, with one
#           or more messages added to it as errors are encountered by
#           some processing task. Errors are added according to codes
#           described by ApiTools::ErrorDescriptions instances.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # During request processing, API service implementations create an
  # ApiTools::Errors instance and add error(s) to the collection as they arise
  # using #add_error. That same instance can then be returned for the on-error
  # handling path of whatever wider service framework is in use by the service
  # code in question. Services should use new instances for each request.
  #
  class Errors

    # Default ApiTools::ErrorDescriptions instance, used if the instantiator
    # provides no alternative.
    #
    DEFAULT_ERROR_DESCRIPTIONS = ApiTools::ErrorDescriptions.new()

    # Errors are manifestations of the Errors resource. They acquire a UUID
    # when instantiated, even if the instance is never used or persisted.
    #
    attr_reader( :uuid )

    # Array of error data - hashes with +code+, +message+ and +reference+
    # fields giving the error codes, human-readable messages and
    # machine-readable reference data, where appropriate.
    #
    attr_reader( :errors )

    # HTTP status code associated with the first error in the #errors array.
    #
    attr_reader( :http_status_code )

    # Create an instance.
    #
    # +descriptions+:: (Optional) ApiTools::ErrorDescriptions instance with
    #                  service-domain-specific error descriptions added, or
    #                  omit for a default instance describing +platform+ and
    #                  +generic+ error domains only.
    #
    def initialize( descriptions = DEFAULT_ERROR_DESCRIPTIONS )
      @uuid             = ApiTools::UUID.generate()
      @descriptions     = descriptions
      @errors           = []
      @http_status_code = 500
      @created_at       = nil # See #persist!
    end

    # Add an error instance to this collection.
    #
    # +code+::      Error code in full, e.g. +generic.invalid_state'.
    #
    # +options+::   An options hash, optional.
    #
    # The options hash contains symbol keys named as follows, with values as
    # described:
    #
    # +:reference+:: Reference data hash, optionality depending upon the error
    #                code and the reference data its error description mandates.
    #                Provide key/value pairs where (symbol) keys are names from
    #                the array of description requirements and values are
    #                strings. All values are concatenated into a single string,
    #                comma-separated. Commas within values are escaped with a
    #                backslash; backslash is itself escaped with a backslash.
    #
    #                You must provide that data at a minimum, but can provide
    #                additional keys too if you so wish. Required keys are
    #                always included first, in order of appearance in the
    #                requirements array of the error declaration, followed by
    #                any extra values in undefined order.
    #
    #                See also ApiTools::ErrorDescriptions::DomainDescriptions#error
    #
    # +:message+::   Optional human-readable for-developer message, +en-nz+
    #                locale. Default messages are provided for all errors, but
    #                if you think you can provide something more informative,
    #                you can do so through this parameter.
    #
    def add_error( code, options = nil )

      options ||= {}
      reference = ApiTools::Utilities.symbolize( options[ :reference ] || {} )
      message   = options[ :message ]

      # Make sure nobody uses an undeclared error code.

      raise "Unknown error code '#{code}'" unless @descriptions.recognised?( code )

      # If the error description specifies a list of required reference keys,
      # make sure all are present and complain if not.

      description = @descriptions.describe( code )

      required_keys = description[ :reference ] || []
      actual_keys   = reference.keys
      missing_keys  = required_keys - actual_keys

      unless ( missing_keys.empty? )
        raise "In #add_error: Reference hash missing required keys: #{ missing_keys.join( ', ' ) }"
      end

      # All good!

      @http_status_code = description[ :status ] || 500 if @errors.empty? # Use first in collection for overall HTTP status code

      error = {
        :code    => code,
        :message => message || description[ :message ] || code
      }

      ordered_keys   = required_keys + ( actual_keys - required_keys )
      ordered_values = ordered_keys.map { | key | escape_commas( reference[ key ] ) }

      # See private method #unjoin_and_unescape_commas to undo the join below.

      error[ :reference ] = ordered_values.join( ',' ) unless ordered_values.empty?

      @errors << error
    end

    # Does this instance have any errors added? Returns +true+ if so,
    # else +false+.
    #
    def has_errors?
      ! @errors.empty?
    end

    # Clear (delete) all previously added errors (if any). After calling here,
    # #has_errors? would always return +false+.
    #
    def clear_errors
      @errors           = []
      @http_status_code = 500
    end

    # Return a Hash rendered through the ApiTools::Data::Resources::Errors
    # collection representing the formalised resource.
    #
    def render
      store!

      ApiTools::Data::Resources::Errors.render(
        { :errors => @errors },
        @uuid,
        @created_at
      )
    end

    # TODO: Persistence - e.g. database locally, or queue if available.
    #
    def store!
      # unless persisted...
      #   created_at = ...

      @created_at ||= Time.now # TODO

      ApiTools::Logger.error(
        "Storing ApiTools::Errors instance"
        JSON.pretty_generate( e.render )
      )
    end

  private

    # Given a string, escape "," to "\," and "\" to "\\", returning the result.
    #
    # +str+:: String to escape.
    #
    def escape_commas( str )
      # "\" in replacement strings gets evaluated twice, once for string
      # literals (leaving '\\\\') then again for regexp group references like
      # "\1" work (thus leaving '\\').
      #
      str.gsub( "\\", "\\\\\\\\" ).gsub( ",", "\\," )
    end

    # Given a string escaped via #escape_commas, unescape it.
    #
    # +str+:: String to escape.
    #
    def unescape_commas( str )
      str.gsub( "\\,", "," ).gsub( "\\\\", "\\\\" )
    end

    # Given a string composed of values escaped with #escape_commas when those
    # values are then concatenated together with a single comma, return an
    # array of the unescaped original values.
    #
    def unjoin_and_unescape_commas( str )

      # In Ruby regular expressions, '(?<!pat)' is a negative lookbehind
      # assertion, making sure that the preceding characters do not match
      # 'pat'. To split the string joined on ',' to an array but not splitting
      # any escaped '\,', then, we can use this rather opaque split regexp:
      #
      #   error[ :reference ].split( /(?<!\\),/ )
      #
      # I.e. split on ',', provided it is not preceded by a '\' (escaped in the
      # regexp to '\\').

      ary = str.split( /(?<!\\),/ )
      ary.map { | entry | unescape_commas( entry ) }
    end
  end
end
