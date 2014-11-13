########################################################################
# File::    utilities.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Miscellaneous useful functions.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

require 'socket'

module ApiTools

  # Useful tools, especially for those working without Rails components.
  #
  module Utilities

    # Given a hash, returns the same hash with keys converted to symbols.
    # Works with nested hashes. Taken from:
    #   http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
    #
    # *WARNING!* In Ruby, Symbols are not garbage collected and will stay in
    # RAM forever. *DO NOT* symbolize hashes containing data provided by an
    # API caller (or any generalised external data) unless you've already
    # made sure that the things you are turning into Symbols are white
    # listed. Otherwise, a malicious (or accidentally misbehaving) caller
    # could cause your code to symbolize a Hash with lots of different strings,
    # filling up memory. Related to:
    #
    #   https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
    #
    # +obj+:: Hash or Array of Hashes. Will recursively convert keys in Hashes
    #         to symbols. Hashes with values that are Arrays of Hashes will be
    #         dealt with properly. Does not modify other types (e.g. an Array
    #         of Strings would stay an Array of Strings).
    #
    # Returns a copy of your input object with keys converted to symbols.
    #
    def self.symbolize(obj)
      return obj.inject({}){|memo,(k,v)| memo[k.to_s.to_sym] =  self.symbolize(v); memo} if obj.is_a?(::Hash)
      return obj.inject([]){|memo,v    | memo                << self.symbolize(v); memo} if obj.is_a?(::Array)
      return obj
    end

    # The keys-to-strings equivalnet of ::symbolize.
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
    def self.spare_port
      server = TCPServer.new( '127.0.0.1', 0 )
      port   = server.addr[ 1 ]

      server.close
      return port
    end
  end
end
