########################################################################
# File::    utilities.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Miscellaneous useful functions.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

require 'socket'

module Hoodoo

  # Useful tools, especially for those working without Rails components.
  #
  module Utilities

    # Given a hash, returns the same hash with keys converted to symbols.
    # Works with nested hashes.
    #
    # +obj+:: Hash or Array of Hashes. Will recursively convert keys in Hashes
    #         to symbols. Hashes with values that are Arrays of Hashes will be
    #         dealt with properly. Does not modify other types (e.g. an Array
    #         of Strings would stay an Array of Strings).
    #
    # Returns a copy of your input object with keys converted to symbols.
    #
    def self.symbolize(obj)

      # http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
      #
      return obj.inject({}){|memo,(k,v)| memo[k.to_s.to_sym] =  self.symbolize(v); memo} if obj.is_a?(::Hash)
      return obj.inject([]){|memo,v    | memo                << self.symbolize(v); memo} if obj.is_a?(::Array)
      return obj
    end

    # The keys-to-strings equivalent of ::symbolize.
    #
    # +obj+:: Hash or Array of Hashes. Will recursively convert keys in Hashes
    #         to strings. Hashes with values that are Arrays of Hashes will be
    #         dealt with properly. Does not modify other types (e.g. an Array
    #         of Symbols would stay an Array of Symbols).
    #
    # Returns a copy of your input object with keys converted to strings.
    #
    def self.stringify(obj)
      return obj.inject({}){|memo,(k,v)| memo[k.to_s] =  self.stringify(v); memo} if obj.is_a?(::Hash)
      return obj.inject([]){|memo,v    | memo         << self.stringify(v); memo} if obj.is_a?(::Array)
      return obj
    end

    # Thorough but slow deep duplication of any object (if it isn't
    # duplicable, e.g. FixNum, you just get the same thing back). Usually
    # used with Hashes or Arrays.
    #
    # +obj+:: Object to duplicate.
    #
    # Returns the duplicated object if duplicable, else returns the input
    # parameter.
    #
    def self.deep_dup( obj )
      duplicate = obj.dup rescue obj

      result = if duplicate.is_a?( Hash )
        duplicate.each { | k, v | duplicate[ k ] = deep_dup( v ) }
      elsif duplicate.is_a?( Array )
        duplicate.map { | entry | deep_dup( entry ) }
      else
        duplicate
      end

      return result
    end

    # Deep merge two hashes.
    #
    # Hash#merge/merge! only do a shallow merge. For example, without
    # a block, when starting with this hash:
    #
    #     { :one => { :two => { :three => 3 } } }
    #
    # ...and merging in this hash:
    #
    #     { :one => { :two => { :and_four => 4 } } }
    #
    # ...the possibly unexpected result is this:
    #
    #     { :one => { :two => { :and_four => 4 } } }
    #
    # Because the value for key ":one" in the original hash is simply
    # overwritten with the value from the merged-in hash.
    #
    # Deep merging takes a target hash, into which an "inbound" source
    # hash is merged and returns a new hash that is the deep merged
    # result. Taking the above example:
    #
    #     target_hash  = { :one => { :two => { :three => 3 } } }
    #     inbound_hash = { :one => { :two => { :and_four => 4 } } }
    #     Hoodoo::Utilities.deep_merge_into( target_hash, inbound_hash )
    #
    # ...yields:
    #
    #     { :one => { :two => { :three => 3, :and_four => 4 } } }
    #
    # For any same-named key with a non-hash value, the value in the
    # inbound hash will overwrite the value in the target hash.
    #
    # Parameters:
    #
    # +target_hash+::  The hash into which something will be merged.
    # +inbound_hash+:: The hash that will be merged into the target.
    #
    # Returns the merged result.
    #
    def self.deep_merge_into( target_hash, inbound_hash )

      # Based on:
      #
      # http://stackoverflow.com/questions/9381553/ruby-merge-nested-hash

      merger = proc { | key, v1, v2 |
        Hash === v1 && Hash === v2 ? v1.merge( v2, &merger ) : v2.nil? ? v1 : v2
      }

      return target_hash.merge( inbound_hash, &merger )
    end

    # Deep diff two hashes. Adapted shamelessly from:
    #
    # http://stackoverflow.com/questions/1766741/comparing-ruby-hashes
    #
    # +hash1+:: "Left hand" hash for comparison.
    # +hash2+:: "Right hand" hash for comparison.
    #
    # The returned result is a Hash itself, potentially nested, with any
    # present key paths leading to an array describing the difference found
    # at that key path. If the two input hashes had values at the path, the
    # differing values are placed in the array ("left hand" value at index
    # 0, "right hand" at index 1). If one input hash has a key leading to
    # a value which the other omits, the array contains +nil+ for the
    # omitted entry.
    #
    # Example:
    #
    #     hash1 = { :foo => { :bar => 2 }, :baz => true, :boo => false }
    #     hash2 = { :foo => { :bar => 3 },               :boo => false }
    #
    #     Hoodoo::Utilities.hash_diff( hash1, hash2 )
    #     # => { :foo => { :bar => [ 2, 3 ] }, :baz => [ true, nil ] }
    #
    #     Hoodoo::Utilities.hash_diff( hash2, hash1 )
    #     # => { :foo => { :bar => [ 3, 2 ] }, :baz => [ nil, true ] }
    #
    # Bear in mind that the difference array contains values of everything
    # different from the first part of the key path where things diverge. So
    # in this case:
    #
    #     hash1 = { :foo => { :bar => { :baz => [ 1, 2, 3 ] } } }
    #     hash2 = {}
    #
    # ...the difference starts all the way up at ":foo". The result is thus
    # *not* a Hash where just the ":baz" array is picked out as a difference;
    # the entire Hash sub-tree is picked out:
    #
    #     diff = Hoodoo::Utilities.hash_diff( hash1, hash2 )
    #     # => { :foo => [ { :bar => { :baz => [ 1, 2, 3 ] } }, nil ] }
    #
    def self.hash_diff( hash1, hash2 )
      return ( hash1.keys | hash2.keys ).inject( {} ) do | memo, key |
        unless hash1[ key ] == hash2[ key ]
          if hash1[ key ].kind_of?( Hash ) && hash2[ key ].kind_of?( Hash )
            memo[ key ] = hash_diff( hash1[ key ], hash2[ key ] )
          else
            memo[ key ] = [ hash1[ key ], hash2[ key ] ]
          end
        end

        memo
      end
    end

    # Convert a (potentially nested) Hash into an array of entries which
    # represent its keys, with the notation "foo.bar.baz" for nested hashes.
    #
    # +hash+:: Input Hash.
    #
    # Example:
    #
    #     hash = { :foo => 1, :bar => { :baz => 2, :boo => { :hello => :world } } }
    #
    #     Hoodoo::Utilities.hash_key_paths( hash )
    #     # => [ 'foo', 'bar.baz', 'bar.boo.hello' ]
    #
    def self.hash_key_paths( hash )
      return hash.map do | key, value |
        if value.is_a?( Hash )
          hash_key_paths( value ).map do | entry |
            "#{ key }.#{ entry }"
          end
        else
          key.to_s
        end
      end.flatten
    end

    # A very single-purpose method which converts an Array of specifc form
    # into a Hash.
    #
    # The Hash class can already build itself from an Array of tuples, thus:
    #
    #    array = [ [ :one, 1 ], [ :two, 2 ] ]
    #    hash  = Hash[ array ]
    #    # => { :one => 1, :two => 2 }
    #
    # This is fine, but what if the array contains the same key twice?
    #
    #    array = [ [ :one, 1 ], [ :two, 2 ], [ :one, 42 ] ]
    #    hash  = Hash[ array ]
    #    # => { :one => 42, :two => 2 }
    #
    # The later duplicates simply override any former entries. This Array
    # collation method is designed to instead take the tuples and set up a
    # Hash where each key leads to an Array of unique values found in the
    # original, thus:
    #
    #    array = [ [ :one, 1 ], [ :two, 2 ], [ :one, 42 ] ]
    #    Hoodoo::Utilities.collated_hash_from( array )
    #    # => { :one => [ 1, 42 ], :two => [ 2 ] }
    #
    # Note that:
    #
    # * The Hash values are always Arrays, even if they only have one value.
    # * The Array values are unique; duplicates are removed via +uniq!+.
    #
    # +array+:: Array of two-element Arrays. The first element becomes a key
    #           in the returned Hash. The last element is added to an Array
    #           of (unique) values associated with that key. An empty Array
    #           results in an empty Hash; +nil+ is not allowed.
    #
    # +dupes+:: Optional. If omitted, duplicates are removed as described;
    #           if present and +true+, duplicates are allowed.
    #
    # Returns a new Hash as described. The input Array is not modified.
    #
    def self.collated_hash_from( array, dupes = false )
      hash_of_arrays = {}

      array.reduce( hash_of_arrays ) do | memo, sub_array |
        memo[ sub_array.first ] = ( memo[ sub_array.first ] || [] ) << sub_array.last
        memo
      end

      hash_of_arrays.values.collect( &:uniq! ) unless dupes == true
      return hash_of_arrays
    end

    # Is a parameter convertable to an integer cleanly? Returns the integer
    # value if so, else +nil+.
    #
    # +value+:: Value to check, e.g. 2, "44", :'55' (yields 2, 44, 55) or
    #           "hello", Time.now (yields nil, nil).
    #
    def self.to_integer?( value )
      value.to_s.to_i if value.to_s.to_i.to_s == value.to_s
    end

    # Return a spare TCP port on localhost. This is free at the instant of
    # calling, though of course if you have anything in other local machine
    # processes/threads running which might start using ports at any moment,
    # there's a chance of the free port getting claimed in between you asking
    # for it and it being returned. This utility method is usually therefore
    # used for test environments only.
    #
    # http://stackoverflow.com/questions/5985822/how-do-you-find-a-random-open-port-in-ruby
    #
    def self.spare_port
      socket = Socket.new( :INET, :STREAM, 0 )
      socket.bind( Addrinfo.tcp( '127.0.0.1', 0 ) )
      port = socket.local_address.ip_port
      socket.close

      return port
    end
  end
end
