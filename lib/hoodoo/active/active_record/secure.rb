########################################################################
# File::    finder.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing enhanced find mechanisms for +show+ and +list+
#           action handling.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # a core out-of-box Hoodoo data access security model. See
    # Hoodoo::ActiveRecord::Secure::ClassMethods#secure for details.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Secure

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Secure
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Secure::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Secure::included.
      #
      module ClassMethods

        # The core of out-of-the-box Hoodoo data access security.
        #
        # In most non-trivial systems, people calling into the system under
        # a Session will have limited access to resource records. Often the
        # broad pattern is: Someone can only see what they create. Maybe
        # there's a superuser-like monitoring concept of someone who can
        # see what everyone creates... In any event, there needs to be some
        # kind of support for this.
        #
        # In the Hoodoo generic case, it's tackled at several levels.
        #
        # * A Caller object can describe fields that are identify who that
        #   Caller is (which may be as simple as the Caller instance's
        #   resource UUID, or may include additional concepts specific to
        #   the API being designed/implemented).
        #
        # * A Session instance is bound to a particular Caller. Someone
        #   calling the API creates a Session using a caller ID and secret,
        #   and gains whatever access permissions and data privileges it
        #   describes.
        #
        # * Custom implementations of a Session resource and Caller resource
        #   endpoint might add in other identifying fields to the session
        #   payload too. That's what the Session's +identity+ section is
        #   for. See Hoodoo::Services::Session#identity.
        #
        # * When resource endpoint implementations create data, they have
        #   an opportunity to use a database field to record (say) the
        #   caller UUID and/or some other session value(s) in indexed table
        #   columns along the lines of "creating_caller_uuid", or similar.
        #   This way, the "who made me" information is preserved.
        #
        # * When resource endpoints read back any data from the database
        #   (for show, list, update or delete actions) the "who made me"
        #   information needs to be compared against 'what the session is
        #   allowed to see'. That's in the Session's +scoping+ section.
        #   See Hoodoo::Services::Session#scoping. For example, a custom
        #   Session resource endpoint might record one or more caller
        #   UUIDs in "scoping.authorised_caller_uuids".
        #
        # Given things along this line, resource endpoints would have to
        # individually scope ActiveRecord +find+ calls to make sure that it
        # only dealt with database records where the 'who made me' data
        # matched up with the 'what can this Session see'. That can be done
        # but it might be error prone, especially if a lot of resource
        # endpoints all have the same data access scoping rules.
        #
        # That's where the ActiveRecord secure context extension comes in.
        # Models declare _mappings_ between database fields and fields in
        # the Session's +scoping+ container. An ActiveRecord::Relation is
        # returned which produces a simple query along the lines of:
        #
        #     Model.where( :database_field => session.scoping.scoped_field )
        #
        # At the time of writing, only simple matches of as shown above can
        # be defined; bespoke resource endpoint implementation code would be
        # needed for something more complex. All you can do is make sure
        # that one or more fields in the database match with one more fields
        # in the Session scoping data.
        #
        # Taking the examples of a database column +creating_caller_uuid+
        # and a Session scoping entry called +authorised_caller_uuids+, a
        # model would do the following to declare the mapped connection
        # between database and session:
        #
        #     class Audit < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Secure
        #
        #       secure_with( {
        #         :creating_caller_uuid => :authorised_caller_uuids
        #       } )
        #     end
        #
        # Then, inside subclass implementation of (for example)
        # Hoodoo::Services::Implementation#list:
        #
        #     def list( context )
        #       secure_scope = Audit.secure( context )
        #     end
        #
        # The 'secure_scope' is just an ActiveRecord::Relation instance;
        # you could call +to_sql+ on the result for debugging and print the
        # result to console if you wanted to see the query built up so far.
        # Otherwise, any of the ActiveRecord::QueryMethods can be called;
        # see:
        #
        # http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html
        #
        # The most common use cases, though, involve finding a specific
        # record or listing records. Hoodoo::ActiveRecord::Finder provides
        # much higher level constructs that build on top of #secure and
        # you are strongly encouraged to use these wherever possible, rather
        # than calling #secure directly.
        #
        # *Important*: If you state a model must be secured by one or more
        # fields, then:
        #
        # * If there is no session at all in the given context, _or_
        # * The session has no scoping data, _or_
        # * The session scoping data does not have one or more of the
        #   fields that the #secure_with map's values describe, _then_
        #
        # ...the returned scope *will* *find* *no* *results*, by design.
        # The default failure mode is to reveal no data at all.
        #
        # Parameters:
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def secure( context )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          extra_scope_map  = class_variable_defined?( :@@nz_co_loyalty_hoodoo_secure_with ) ?
                                  class_variable_get( :@@nz_co_loyalty_hoodoo_secure_with ) :
                                  nil

          unless extra_scope_map.nil?
            return none() if context.session.nil? || context.session.scoping.nil?

            extra_scope_map.each do | model_field_name, session_scoping_key |
              if context.session.scoping.respond_to?( session_scoping_key )
                prevailing_scope = prevailing_scope.where( {
                  model_field_name => context.session.scoping.send( session_scoping_key )
                } )
              else
                prevailing_scope = none()
                break
              end
            end
          end

          # TODO: I18n via context.request.locale.

          return prevailing_scope
        end

        # Declare the mapping between database columns and Session scoping
        # entries. See #secure for details and examples.
        #
        # Parameters:
        #
        # +map+:: A Hash of String or Symbol keys and values that gives the
        #         secure mapping details. The keys are names of fields in
        #         the model. The values are names of fields in the
        #         Hoodoo::Services::Session#scoping object.
        #
        def secure_with( map )
          class_variable_set( '@@nz_co_loyalty_hoodoo_secure_with', map )
        end
      end
    end
  end
end
