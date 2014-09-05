module ApiTools
  class ThreadSafeHash
    def initialize
      @hash = Hash.new
      @mutex = Mutex.new
    end

    def [](index)
      result = nil
      @mutex.synchronize {
        result = @hash[index]
      }
      result
    end

    def []=(index,value)
      result = nil
      @mutex.synchronize {
        result = @hash[index] = value
      }
      result
    end

    def has_key?(index)
      result = nil
      @mutex.synchronize {
        result = @hash.has_key?(index)
      }
      result
    end

    def delete(index)
      result = nil
      @mutex.synchronize {
        result = @hash.delete(index)
      }
      result
    end
  end
end