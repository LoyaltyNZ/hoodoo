########################################################################
# File::    headers.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: If you can't think of where some code should live, use a
#           Class or Module as a namespace for what amounts to library
#           routines. The class defined here has support data and code
#           for Hoodoo::Client, Hoodoo::Services::Middleware and others.
# ----------------------------------------------------------------------
#           22-Sep-2015 (ADH): Created.
########################################################################

module Hoodoo
  class Client

    # Hoodoo::Client and related software such as
    # Hoodoo::Services::Middleware need common access to information about
    # special processing headers defined by Hoodoo and the Hoodoo API. This
    # class is just a container - pretty much a namespaced library - holding
    # that kind of information and support methods.
    #
    class Headers

      # Used by HEADER_TO_PROPERTY; this Proc when called with some non-nil
      # value from an HTTP header representing a UUID, evaluates to either the
      # UUID as a String or +nil+ if the value appeared to not be a UUID.
      #
      UUID_PROPERTY_PROC = -> ( value ) {
        value = Hoodoo::UUID.valid?( value ) && value
        value || nil # => 'value' if 'value' is truthy, 'nil' if 'value' falsy
      }

      # Used by HEADER_TO_PROPERTY; this Proc when called with some UUID
      # evaluates to the input value coerced to a String and no other changes.
      #
      UUID_HEADER_PROC = -> ( value ) { value }

      # Used by HEADER_TO_PROPERTY; this Proc when called with some non-nil
      # value from an HTTP header representing a Date/Time in a supported
      # format, evaluates to either a parsed DateTime instance or +nil+ if the
      # value appeared to not be in a supported format.
      #
      DATETIME_IN_PAST_ONLY_PROPERTY_PROC = -> ( value ) {
        value = Hoodoo::Utilities.valid_iso8601_subset_datetime?( value )
        value = nil if value && value > DateTime.now
        value || nil # => 'value' if 'value' is truthy, 'nil' if 'value' falsy
      }

      # Used by HEADER_TO_PROPERTY; this Proc is called with a Time, Date,
      # DateTime or DateTime-parseable String and returns a DateTime. It is
      # used for a custom write accessor for the property associated with
      # a header entry and works independently of the validation mechanism
      # for inbound String-only from-header data.
      #
      DATETIME_WRITER_PROC = -> ( value ) { Hoodoo::Utilities.rationalise_datetime( value ) }

      # Used by HEADER_TO_PROPERTY; this Proc when called with a DateTime
      # instance evaluates to a String representing the DateTime as an
      # ISO 8601 subset value given to nanosecond precision.
      #
      DATETIME_HEADER_PROC = -> ( value ) { Hoodoo::Utilities.nanosecond_iso8601( value ) }

      # Used by HEADER_TO_PROPERTY; this Proc when called with some non-nil
      # value from an HTTP header representing a Boolean as "yes" or "no",
      # evaluates to either +true+ for "yes" or +false+ for any other value.
      # Case insensitive.
      #
      BOOLEAN_PROPERTY_PROC = -> ( value ) {
        value.to_s.downcase == 'yes' || value == true ? true : false
      }

      # Used by HEADER_TO_PROPERTY; this Proc when called with +true+ or
      # +false+ evaluates to String "yes" for +true+ or "no" for any other
      # value.
      #
      BOOLEAN_HEADER_PROC = -> ( value ) { value == true ? 'yes' : 'no' }

      # Various "X-Foo"-style HTTP headers specified in the Hoodoo API
      # Specification have special meanings and values for those need to be
      # set up in request data and Hoodoo::Client endpoints. Processing
      # around these is data driven by this mapping Hash.
      #
      # Keys are the HTTP header names in Rack (upper case, "HTTP_"-prefix)
      # format. Values are options bundles as follows:
      #
      # +property+::      The property name to be associated with the header,
      #                   as a Symbol.
      #
      # +property_proc+:: A Proc that's called to both validate and clean up
      #                   the raw value from the HTTP header. It evaluates to
      #                   +nil+ if the value is invalid, or non-+nil+ for any
      #                   other case. Note that there is no way for an HTTP
      #                   header to explicitly convey a corresponding value
      #                   internally of +nil+ as a result, by design; instead
      #                   the relevant header would simply be omitted by the
      #                   caller (and/or change your header design!).
      #
      # +writer_proc+::   If a property has a possible amigbuity of input
      #                   data types when set externally, independently of
      #                   any validation etc. from the +property_proc+
      #                   option, then this optional entry contains a Proc
      #                   that is used for a custom write accessor and
      #                   canonicalises assumed-valid but possibly not
      #                   canonical input for writing. An example would be
      #                   the conversion of String or Time instances to a
      #                   DateTime so that a property always reads back with
      #                   a DateTime instance.
      #
      # +header+::        For speed in lookups where it's needed, this is the
      #                   "real" (not Rack format) HTTP header name.
      #
      # +header_proc+::   A Proc that's called to convert a cleaned-up value
      #                   set in the +property+ by its +property_proc+. It
      #                   is called with this value and returns an equivalent
      #                   appropriate value for use with the HTTP header
      #                   given in +header+. This _MUST_ always be a String.
      #
      # +secured+::       Optional, default +nil+. If +true+, marks that
      #                   this header and its associated value can only be
      #                   processed if there is a Session with a Caller that
      #                   has an +authorised_http_headers+ entry for this
      #                   header.
      #
      # +auto_transfer+:: Optional, default +nil+. Only relevant to
      #                   inter-resource call scenarios. If +true+, when one
      #                   resource calls another, the value of this property
      #                   is automatically transferred to the downstream
      #                   resource. Otherwise, it is not, and the downstream
      #                   resource will operate under whatever defaults are
      #                   present. An inter-resource call endpoint which
      #                   inherits an auto-transfer property can always have
      #                   this property explicitly overwritten before any
      #                   calls are made through it.
      #
      # An additional key of +:property_writer+ will be set up automatically
      # which contains the value of the +:property+ key with an "=" sign added,
      # resulting in the name of a write accessor method for that property.
      #
      HEADER_TO_PROPERTY =
      {
        # Take care not to define any property name which clashes with an
        # option in any other part of this entire system where these "other
        # options" get merged in. A project search for
        # 'HEADER_TO_PROPERTY' in comments should find those.

        'HTTP_X_RESOURCE_UUID' => {
          :property      => :resource_uuid,
          :property_proc => UUID_PROPERTY_PROC,
          :header        => 'X-Resource-UUID',
          :header_proc   => UUID_HEADER_PROC,

          :secured       => true,
        },

        'HTTP_X_DATED_AT' => {
          :property      => :dated_at,
          :property_proc => DATETIME_IN_PAST_ONLY_PROPERTY_PROC,
          :writer_proc   => DATETIME_WRITER_PROC,
          :header        => 'X-Dated-At',
          :header_proc   => DATETIME_HEADER_PROC,

          :auto_transfer => true,
        },

        'HTTP_X_DATED_FROM' => {
          :property      => :dated_from,
          :property_proc => DATETIME_IN_PAST_ONLY_PROPERTY_PROC,
          :writer_proc   => DATETIME_WRITER_PROC,
          :header        => 'X-Dated-From',
          :header_proc   => DATETIME_HEADER_PROC,

          :auto_transfer => true,
        },

        'HTTP_X_DEJA_VU' => {
          :property      => :deja_vu,
          :property_proc => BOOLEAN_PROPERTY_PROC,
          :header        => 'X-Deja-Vu',
          :header_proc   => BOOLEAN_HEADER_PROC,
        },
      }

      # For speed, fill in a "property_writer" value, where "foo" becomes
      # "foo=" - otherwise this has to be done in lots of speed-sensitive
      # code sections.
      #
      HEADER_TO_PROPERTY.each_value do | value |
        value[ :property_writer ] = "#{ value[ :property ] }="
      end

      # Define a series of read and custom write accessors according to the
      # HTTP_HEADER_OPTIONS_MAP. For example, a property of "dated_at" results
      # in a <tt>dated_at</tt> reader, a <tt>dated_at=</tt> writer which calls
      # Hoodoo::Utilities.rationalise_datetime to clean up the input value
      # and sets the result into the <tt>@dated_at</tt> instance variable which
      # the read accessor will be expecting to use.
      #
      # +klass+:: The Class to which the instance methods will be added.
      #
      def self.define_accessors_for_header_equivalents( klass )
        klass.class_eval do
          HEADER_TO_PROPERTY.each do | rack_header, description |
            attr_reader( description[ :property ] )

            custom_writer = description[ :writer_proc ]

            if custom_writer.nil?
              attr_writer( description[ :property ] )
            else
              define_method( "#{ description[ :property ] }=" ) do | parameter |
                instance_variable_set(
                  "@#{ description[ :property ] }",
                  description[ :writer_proc ].call( parameter )
                )
                result = instance_variable_get("@#{ description[ :property ] }")
              end
            end
          end
        end
      end
    end
  end
end
