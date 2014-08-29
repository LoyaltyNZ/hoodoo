module ApiTools
  module PlatformErrors

    def clear_errors
      @errors = []
    end

    def add_error(code, message, reference = nil)
      clear_errors if @errors.nil?

      err = {:code=>code, :message=>message}
      err[:reference] = reference unless reference.nil?
      @errors << err
    end

    def has_errors?
      !@errors.nil? && @errors.count > 0
    end
    
  end
end