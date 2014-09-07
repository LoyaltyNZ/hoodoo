module ApiTools
  class ThreadSafeHash

    attr_accessor :hash, :mutex 

    def initialize
      @hash = Hash.new
      @mutex = Mutex.new
    end

    def [](index)
      @mutex.synchronize {
        @hash[index]
      }
    end

    def []=(index,value)
      @mutex.synchronize {
        @hash[index] = value
      }
    end

    def has_key?(index)
      @mutex.synchronize {
        @hash.has_key?(index)
      }
    end

    def delete(index)
      @mutex.synchronize {
        @hash.delete(index)
      }
    end
  end
end