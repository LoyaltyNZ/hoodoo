########################################################################
# File::    secure.rb
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

        model.class_attribute(
          :nz_co_loyalty_hoodoo_secure_with,
          {
            :instance_predicate => false,
            :instance_accessor  => false
          }
        )

        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Secure::included.
      #
      module ClassMethods

        # The core of out-of-the-box Hoodoo data access security layer.
        #
        # Parameters:
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # == Overview
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
        # == Automatic session-based finder scoping
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
        # == Rendering resources
        #
        # Models aren't directly connected to Resource representations, but
        # since the security later interfaces with session data herein, there
        # is clearly an intersection of concepts. Even though fields in a
        # Model may not map directly to fields in a related Resource (or
        # many Models might contribute to a Resource), the security scoping
        # rules that led to the limitations on data retrieval may be useful
        # to an API caller. The API basic definitions support this through
        # a +secured_with+ standard (but optional) resource field.
        #
        # The +secured_with+ field's value is an object of key/value pairs.
        # Its contents depend on how the #secure_with method is used in a
        # model. The #secure_with call actually supports _two_ modes of
        # operation. One is as already shown above; suppose we have:
        #
        #     secure_with( {
        #       :creating_caller_uuid => :authorised_caller_uuids,
        #       :programme_code       => :authorised_programme_codes
        #     } )
        #
        # If Hoodoo::Presenters::Base::render_in is called and an instance of
        # a model with the above declaration is passed in the +secured_with+
        # option, then the keys from the declaration appear in the resource
        # representation's +secured_with+ field's object and the values are
        # the _actual_ scoping values which were used, i.e. the rendered
        # data would contain:
        #
        #     {
        #       "id": "<UUID>",
        #       "kind": "Example",
        #       "created_at": "2015-04-30T16:25:17+12:00",
        #       "secured_with": {
        #         "creating_caller_uuid": "<UUID>",
        #         "programme_code": "<code>"
        #       },
        #       ...
        #     }
        #
        # This binds the field values in the model to the values in the
        # rendered resource representation, though; and what if we only wanted
        # (say) the "creating_caller_uuid" to be revealed, but did not want to
        # show the "programme_code" value? To do this, instead of passing a
        # Symbol in the values of the #secure_with options, you provide a Hash
        # of options for that particular security entry. Option keys are
        # Symbols:
        #
        # +session_field_name+::  This is the field that's looked up in the
        #                         session's scoping section.
        #
        # +resource_field_name+:: This is the name that'll appear in the
        #                         rendered resource.
        #
        # +hide_from_resource+::  If present and set to +true+, the entry will
        #                         not be shown; else it is shown by default
        #                         (if you're passing in a model instance to a
        #                         render call via the +secured_with+ option it
        #                         is assumed that you explicitly _do_ want to
        #                         include this kind of information rather than
        #                         hide it).
        #
        # To help clarify the above, the following two calls to #secure_with
        # have exactly the same effect.
        #
        #     secure_with( {
        #       :creating_caller_uuid => :authorised_caller_uuids
        #     } )
        #
        #     # ...is equivalent to...
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name  => :authorised_caller_uuids,
        #         :resource_field_name => :creating_caller_uuid, # (Or just omit this option)
        #         :hide_from_resource  => false # (Or just omit this option)
        #       }
        #     } )
        #
        # Taking the previous example, let's change the name of the field shown
        # in the resource and hide the "programme_code" entry:
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name  => :authorised_caller_uuids,
        #         :resource_field_name => :caller_id # Note renaming of field
        #       },
        #       :programme_code => {
        #         :session_field_name => :authorised_programme_codes,
        #         :hide_from_resource => true
        #       }
        #     } )
        #
        # ...would lead to a rendered resource looking something like this:
        #
        #     {
        #       "id": "<UUID>",
        #       "kind": "Example",
        #       "created_at": "2015-04-30T16:25:17+12:00",
        #       "secured_with": {
        #         "caller_id": "<UUID>",
        #       },
        #       ...
        #     }
        #
        # == Important
        #
        # If you state a model must be secured by one or more fields, then:
        #
        # * If there is no session at all in the given context, _or_
        # * The session has no scoping data, _or_
        # * The session scoping data does not have one or more of the
        #   fields that the #secure_with map's values describe, _then_
        #
        # ...the returned scope *will* *find* *no* *results*, by design.
        # The default failure mode is to reveal no data at all.
        #
        def secure( context )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          extra_scope_map  = secured_with()

          unless extra_scope_map.nil?
            return none() if context.session.nil? || context.session.scoping.nil?

            extra_scope_map.each do | model_field_name, key_or_options |
              if key_or_options.is_a?( Hash )
                session_scoping_key = key_or_options[ :session_field_name ]
              else
                session_scoping_key = key_or_options
              end

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
        #         Hoodoo::Services::Session#scoping object, or can be a Hash
        #         of options; see #secure for full details and examples.
        #
        def secure_with( map )
          self.nz_co_loyalty_hoodoo_secure_with = map
        end

        # Retrieve the mapping declared between database columns and
        # Session scoping entries via #secure_with. Returns a map as passed
        # to #secure_with, or +nil+ if no such declaration has been made.
        #
        def secured_with
          self.nz_co_loyalty_hoodoo_secure_with
        end
      end
    end
  end
end
