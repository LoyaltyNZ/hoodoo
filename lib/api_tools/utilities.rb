module ApiTools

  # Useful tools, especially for those working without Rails components.
  #
  module Utilities

    # Given a hash, returns the same hash with keys converted to symbols.
    # Works with nested hashes. Taken from:
    #
    #   http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
    #
    def self.symbolize(obj)
      return obj.inject({}){|memo,(k,v)| memo[k.to_s.to_sym] =  self.symbolize(v); memo} if obj.is_a?(::Hash)
      return obj.inject([]){|memo,v    | memo                << self.symbolize(v); memo} if obj.is_a?(::Array)
      return obj
    end
  end
end
