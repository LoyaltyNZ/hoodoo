########################################################################
# File::    transient_store.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Provide a simple abstraction over transient storage engines
#           such as Memcached or Redis, making it easier for client code
#           to switch engines with very few changes.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

module Hoodoo

  # A simple abstraction over transient storage engines such as Memcached or
  # Redis, making it easier for client code to switch engines with very few
  # changes. If the storage engine chosen when creating instances of this
  # object is defined in application-wide configuration data, all you would
  # need to do is change that configuration for all transient data use to
  # switch over to the new engine.
  #
  class TransientStore

    ###########################################################################
    # Class methods
    ###########################################################################

    # Register a new storage class. It _MUST_ inherit from and thus follow the
    # template laid out in Hoodoo::TransientStore::Base.
    #
    # _Named_ parameters are:
    #
    # +as+:
    #
    def self.register( as:, using: )
      if @@supported_storage_engines.has_key?( as )
        raise "Hoodoo::TransientStore: A storage engine called '#{ as }' is already registered"
      end

      @@supported_storage_engines[ as ] = using
    end

    def self.deregister( as: )
      @@supported_storage_engines.delete( as )
    end

    def self.supported_storage_engines
      @@supported_storage_engines.keys
    end

    ###########################################################################
    # Instance methods
    ###########################################################################

    # Read this instance's storage engine; see #supported_storage_engines and
    # #initialize.
    #
    attr_reader :storage_engine

    # Read this instance's default item maximum lifespan, in sections. See
    # also #initialize.
    #
    attr_reader :default_maximum_lifespan

    # Instantiate a new Transient storage object through which temporary data
    # can be stored or retrieved.
    #
    # The TransientStore abstraction is a high level and simple abstraction over
    # heterogenous data storage engines. It does not expose the many subtle
    # configuration settings usually available in such. If you need to take
    # advantage of those at an item storage level, you'll need to use a lower
    # level interface and thus lock your code to the engine of choice.
    #
    # Engine plug-ins are recommended to attempt to gain and test a connection
    # to the storage engine when this object is constructed, so if building a
    # TransientStore instance, ensure your chosen storage engine is running
    # first.
    #
    # _Named_ parameters are:
    #
    # +storage_engine+::           An entry from #supported_storage_engines.
    #
    # +storage_host_uri+::         The engine-dependent connection URI. Consult
    #                              documentation for your chosen engine to find
    #                              out its connection URI requirements, along
    #                              with the documentation for the constructor
    #                              method of the plug-in in use, since in some
    #                              cases requirements may be unusual (e.g. in
    #                              Hoodoo::TransientStore::MemcachedRedisMirror).
    #
    # +default_maximum_lifespan+:: The default time-to-live for data items, in,
    #                              seconds; can be overridden per item; default
    #                              is 604800 seconds or 7 days.
    #
    def initialize(
      storage_engine:,
      storage_host_uri:,
      default_maximum_lifespan: 604800
    )

      unless @@supported_storage_engines.include?( storage_engine)

        # Be kind and use 'inspect' to indicate that we expect Symbols here
        # in the exception, because of the arising leading ':' in the output.
        #
        engines = @@supported_storage_engines.map { | symbol | "'#{ symbol.inspect }'" }
        allowed = engines.join( ', ' )

        raise "Hoodoo::TransientStore: Unrecognised storage engine '#{ storage_engine.inspect }' requested; allowed values: #{ allowed }"
      end

      @default_maximum_lifespan = default_maximum_lifespan
      @storage_engine           = storage_engine
      @storage_engine_instance  = @@supported_storage_engines[ storage_engine ].new(
        storage_host_uri: storage_host_uri
      )

    end

    # Set (write) a given payload into the storage engine with the given
    # payload and maximum lifespan.
    #
    # Payloads must only contain simple types such as Hash, Array, String and
    # Integer. Complex types like Symbol, Date, Float, BigDecimal or custom
    # objects are unlikely to serialise properly but since this depends upon
    # the storage engine in use, errors may or may not be raised for misuse.
    #
    # Storage engines usually have a maximum payload size limit; consult your
    # engine administrator for information. For example, the default - but
    # reconfigurable - maximum payload size for Memcached is 1MB.
    #
    # For maximum possible compatibility:
    #
    # * Use only Hash payloads with String key/value paids and no nesting. You
    #   may choose to marshal the data into a String manually for unusual data
    #   requirements, manually converting back when reading stored data.
    #
    # * Keep the payload size as small as possible - large objects belong in
    #   bulk storage engines such as Amazon S3.
    #
    # These are only guidelines though - heterogenous storage engine support
    # and the ability of system administrators to arbitrarily configure those
    # storage engines makes it impossible to be more precise.
    #
    # Returns:
    #
    # * +true+ if storage was successful
    # * +false+ if storage failed but the reason is unknown
    # * An +Exception+ instance if storage failed and the storage engine
    #   raised an exception describing the problem.
    #
    # _Named_ parameters are:
    #
    # +key+:              Storage key to use in the engine, which is then used
    #                     in subsequent calls to #get and possibly eventually
    #                     to #delete. Only non-empty Strings or Symbols are
    #                     permitted, else an exception will be raised.
    #
    # +payload+:          Payload data to store under the given +key+. A flat
    #                     Hash is recommended rather than simple types such as
    #                     String (unless marshalling a complex type into such)
    #                     in order to make potential additions to stored data
    #                     easier to implement. Note that +nil+ is prohibited.
    #
    # +maximum_lifespan+: Optional maximum lifespan in seconds. Storage engines
    #                     may chooset to evict payloads sooner than this, so it
    #                     is a maximum time, not a guarantee. Omit to use this
    #                     TransientStore instance's default value - see
    #                     #initialize. If you know you no longer need a piece
    #                     of data at a particular point in the execution flow
    #                     of your code, explicitly delete it via #delete rather
    #                     than leaving it to expire. This maximises the storage
    #                     engine's pool free space and in turn minimises the
    #                     chance of it evicting stored items early.
    #
    def set( key:, payload:, maximum_lifespan: nil )
      key = self.normalise_key( key, 'set' )

      if payload.nil?
        raise "Hoodoo::TransientStore\#set: Payloads of 'nil' are prohibited"
      end

      maximum_lifespan ||= @default_maximum_lifespan

      begin
        result = @storage_engine_instance.set(
          key:              key,
          payload:          payload,
          maximum_lifespan: maximum_lifespan
        )
      rescue => e
        result = e
      end

      return result
    end

    # Retrieve data previously stored with #set.
    #
    # _Named_ parameters are:
    #
    # +key+: Key previously given to #set.
    #
    # Returns +nil+ if the item is not found - either the key is wrong, the
    # stored data has expired or the stored data has been evicted early from
    # the storage engine's pool.
    #
    # Only non-empty String or Symbol keys are permitted, else an exception
    # will be raised.
    #
    def get( key: )
      key = self.normalise_key( key, 'get' )

      begin
        @storage_engine_instance.get( key )
      rescue
        nil
      end
    end

    # Delete data previously stored with #set.
    #
    # _Named_ parameters are:
    #
    # +key+: Key previously given to #set.
    #
    # If the item has already been expired, evicted or the key is simply not
    # recognised, the method returns silently.
    #
    # Only non-empty String or Symbol keys are permitted, else an exception
    # will be raised.
    #
    def delete( key: )
      key = self.normalise_key( key, 'delete' )

      begin
        @storage_engine_instance.delete( key )
      rescue
        nil
      end
    end

  private

    # Given a storage key, make sure it's a String or Symbol, coerce to a
    # String and ensure it isn't empty. Returns the non-empty String version.
    # Raises exceptions for bad input classes or empty keys.
    #
    # +key+:                 Key to normalise.
    #
    # +calling_method_name+: Name of calling method to declare in exception
    #                        messages, to aid callers in debugging.
    #
    def normalise_key( key, calling_method_name )
      unless key.is_a?( String ) || key.is_a?( Symbol )
        raise "Hoodoo::TransientStore\##{ calling_method_name }: Keys must be of String or Symbol class; you provided '#{ key.class }'"
      end

      key = key.to_s

      if key.empty?
        raise "Hoodoo::TransientStore\##{ calling_method_name }: Empty String or Symbol keys are prohibited"
      end

      return key
    end
  end
end
