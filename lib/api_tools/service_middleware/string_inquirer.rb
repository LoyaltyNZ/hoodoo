########################################################################
# File::    string_inquirer.rb
#
# Purpose:: StringInquirer class copied from ActiveSupport 4.1.6, to
#           avoid dragging in that huge dependency for this one thing.
# ----------------------------------------------------------------------
#           02-Oct-2014 (ADH): Copied from ActiveSupport 4.1.6.
########################################################################

module ApiTools

  # Given a string, provides an object that takes the string's value and
  # turns it into a method "#{value}?", returning +true+; other methods
  # all respond +false+.
  #
  # Example:
  #
  #     greeting = ApiTools::StringInquirer.new( 'hello' )
  #     greeting.hello? # => true
  #     greeting.hi?    # => false
  #
  class StringInquirer < String

    private

      # Asks if this object can respond to a given method. In practice returns
      # +true+ for any method name ending in "?".
      #
      # +method_name+::     Method name to ask about
      # +include_private+:: If +true+ include private methods in the test,
      #                     else if omitted or +false+, ignore them.
      #
      def respond_to_missing?( method_name, include_private = false )
        method_name[ -1 ] == '?'
      end

      # Called when a String receives a message it cannot handle. This is where
      # StringInquirer adds in its string-value-dependent "fake" boolean method.
      # For any method name ending in "?", returns +true+ if the string value
      # matches the name except for that "?", else +false+. If the method name
      # does not end in "?", the call is passed to +super+.
      #
      # +method_name+:: Method name that wasn't found in object instance.
      # *arguments::    List of arguments passed to the method.
      #
      def method_missing( method_name, *arguments )
        if method_name[ -1 ] == '?'
          self == method_name[ 0..-2 ]
        else
          super
        end
    end
  end
end
