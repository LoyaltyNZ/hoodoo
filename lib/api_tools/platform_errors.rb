module ApiTools
  # A module intended as a generic error handler for an instance of a class. 
  # Provides multiple error capability for a class in the standard platform error 
  # format.
  module PlatformErrors

    # Clear all errors.
    def clear_errors
      @errors = []
    end

    # Add an error with the specified `code`, `message`, and optionally `reference` 
    # to the error list.
    def add_error(code, message, reference = nil)
      clear_errors if @errors.nil?

      err = {:code=>code, :message=>message}
      err[:reference] = reference unless reference.nil?
      @errors << err
    end

    # Return `true` if errors have been added.
    def has_errors?
      !@errors.nil? && @errors.count > 0
    end
    
  end
end