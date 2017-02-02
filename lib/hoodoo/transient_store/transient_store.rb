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

  # A simple abstraction over transient storage engines such as
  # {Memcached}[https://memcached.org] or {Redis}[https://redis.io], making it
  # it easier for client code to switch engines with very few changes. If the
  # storage engine chosen when creating instances of this object is defined in
  # application-wide configuration data, all you would need to do is change the
  # configuration for all new TransientStore instances to use the new engine.
  #
  class TransientStore

    ###########################################################################
    # Class methods
    ###########################################################################

    # Register a new storage engine plugin class. It _MUST_ inherit from and
    # thus follow the template laid out in Hoodoo::TransientStore::Base.
    #
    # _Named_ parameters are:
    #
    # +as+::    The name, as a Symbol, for the ::new +storage_engine+
    #           input parameter, to select this plugin.
    #
    # +using+:: The class reference of the Hoodoo::TransientStore::Base
    #           subclass to be associated with the name given in +as+.
    #
    # Example:
    #
    #     Hoodoo::TransientStore.register(
    #       as:    :memcached,
    #       using: Hoodoo::TransientStore::Memcached
    #     )
    #
    def self.register( as:, using: )
      as = as.to_sym

      @@supported_storage_engines = {} unless defined?( @@supported_storage_engines )

      unless using < Hoodoo::TransientStore::Base
        raise "Hoodoo::TransientStore.register requires a Hoodoo::TransientStore::Base subclass - got '#{ using.to_s }'"
      end

      if @@supported_storage_engines.has_key?( as )
        raise "Hoodoo::TransientStore.register: A storage engine called '#{ as }' is already registered"
      end

      @@supported_storage_engines[ as ] = using
    end

    # Remove a storage engine plugin class from the supported collection. Any
    # existing Hoodoo::TransientStore instances using the removed class will
    # not be affected, but new instances cannot be made.
    #
    # _Named_ parameters are:
    #
    # +as+:: The value given to #register in the corresponding +as+ parameter.
    #
    def self.deregister( as: )
      @@supported_storage_engines.delete( as )
    end

    # Return an array of the names of all supported storage engine names known
    # to the Hoodoo::TransientStore class. Any one of those names can be used
    # with the ::new +storage_engine+ parameter.
    #
    def self.supported_storage_engines
      @@supported_storage_engines.keys()
    end

    ###########################################################################
    # Instance methods
    ###########################################################################

    # Read this instance's storage engine; see ::supported_storage_engines and
    # ::new.
    #
    attr_reader :storage_engine

    # Read the storage engine insteance for the #storage_engine - this allows
    # engine-specific configuration to be set where available, though this is
    # strongly discouraged as it couples client code to the engine in use,
    # defeating the main rationale behind the TransientStore abstraction.
    #
    attr_reader :storage_engine_instance

    # Read this instance's default item maximum lifespan, in sections. See
    # also ::new.
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
    # first. Exceptions may be raised by storage engines, so you will probably
    # want to catch those with more civilised error handling code.
    #
    # _Named_ parameters are:
    #
    # +storage_engine+::           An entry from ::supported_storage_engines.
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

      unless self.class.supported_storage_engines().include?( storage_engine )

        # Be kind and use 'inspect' to indicate that we expect Symbols here
        # in the exception, because of the arising leading ':' in the output.
        #
        engines = self.class.supported_storage_engines().map { | symbol | "'#{ symbol.inspect }'" }
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
    # +key+::              Storage key to use in the engine, which is then used
    #                      in subsequent calls to #get and possibly eventually
    #                      to #delete. Only non-empty Strings or Symbols are
    #                      permitted, else an exception will be raised.
    #
    # +payload+::          Payload data to store under the given +key+. A flat
    #                      Hash is recommended rather than simple types such as
    #                      String (unless marshalling a complex type into such)
    #                      in order to make potential additions to stored data
    #                      easier to implement. Note that +nil+ is prohibited.
    #
    # +maximum_lifespan+:: Optional maximum lifespan, seconds. Storage engines
    #                      may chooset to evict payloads sooner than this; it
    #                      is a maximum time, not a guarantee. Omit to use this
    #                      TransientStore instance's default value - see ::new.
    #                      If you know you no longer need a piece of data at a
    #                      particular point in the execution flow of your code,
    #                      explicitly delete it via #delete rather than leaving
    #                      it to expire. This maximises the storage engine's
    #                      pool free space and so minimises the chance of early
    #                      item eviction.
    #
    def set( key:, payload:, maximum_lifespan: nil )
      key = normalise_key( key, 'set' )

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

        if result != true && result != false
          raise "Hoodoo::TransientStore\#set: Engine '#{ @storage_engine }' returned an invalid response"
        end

      rescue => e
        result = e

      end

      return result
    end

    # Retrieve data previously stored with #set.
    #
    # _Named_ parameters are:
    #
    # +key+:: Key previously given to #set.
    #
    # Returns +nil+ if the item is not found - either the key is wrong, the
    # stored data has expired or the stored data has been evicted early from
    # the storage engine's pool.
    #
    # Only non-empty String or Symbol keys are permitted, else an exception
    # will be raised.
    #
    def get( key: )
      key = normalise_key( key, 'get' )
      @storage_engine_instance.get( key: key ) rescue nil
    end

    # Delete data previously stored with #set.
    #
    # _Named_ parameters are:
    #
    # +key+:: Key previously given to #set.
    #
    # Returns:
    #
    # * +true+ if deletion was successful, if the item has already expired or
    #   if the key is simply not recognised so there is no more work to do.
    # * +false+ if deletion failed but the reason is unknown.
    # * An +Exception+ instance if deletion failed and the storage engine
    #   raised an exception describing the problem.
    #
    # Only non-empty String or Symbol keys are permitted, else an exception
    # will be raised.
    #
    def delete( key: )
      key = normalise_key( key, 'delete' )

      begin
        result = @storage_engine_instance.delete( key: key )

        if result != true && result != false
          raise "Hoodoo::TransientStore\#delete: Engine '#{ @storage_engine }' returned an invalid response"
        end

      rescue => e
        result = e

      end

      return result
    end

  private

    # Given a storage key, make sure it's a String or Symbol, coerce to a
    # String and ensure it isn't empty. Returns the non-empty String version.
    # Raises exceptions for bad input classes or empty keys.
    #
    # +key+::                 Key to normalise.
    #
    # +calling_method_name+:: Name of calling method to declare in exception
    #                         messages, to aid callers in debugging.
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
