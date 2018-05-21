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

require 'hoodoo/active/active_record/security_helper'

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

      # Instantiates this module when it is included.
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
        model.class_attribute(
          :nz_co_loyalty_hoodoo_secure_with,
          {
            :instance_predicate => false,
            :instance_accessor  => false
          }
        )

        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
        super( model )
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

      # Convenience constant defining an equals-single-security-value wildcard
      # security exemption using the String '*'.
      #
      OBJECT_EQLS_STAR = Hoodoo::ActiveRecord::Secure::SecurityHelper::eqls_wildcard( '*' )

      # Convenience constant defining an included-in-enumerable-security-value
      # wildcard security excemption using the String '*'.
      #
      ENUMERABLE_INCLUDES_STAR = Hoodoo::ActiveRecord::Secure::SecurityHelper::includes_wildcard( '*' )

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Secure::included.
      #
      module ClassMethods

        # Internal.
        #
        # See #secure for details - this is the Proc used by default if no
        # alternative argument generator is given in the longhand form's
        # value Hash's +:using+ key.
        #
        DEFAULT_SECURE_PROC = Proc.new do | model_class, database_column_name, session_field_value |
          [ { database_column_name => session_field_value } ]
        end

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
        # For more advanced query conditions that a single database column
        # checked against a session value with an implicit +AND+, see later.
        #
        # == Important!
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
        # +using+::               See the _Advanced_ _query_ _conditions_
        #                         section later for details.
        #
        # +exemptions+::          See the _Security_ _exemptions_ section later
        #                         for details.
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
        # == Advanced query conditions
        #
        # A simple implicit +AND+ clause on a single database column might
        # not be sufficient for your scoping. In this case, the "longhand"
        # Hash form described for rendering is used, this time including the
        # key +:using+ to specify a Proc that is executed to return an array
        # of parameters for <tt>where</tt>. For example:
        #
        #     secure_with( {
        #       :creating_caller_uuid => :authorised_caller_uuids
        #     } )
        #
        #     # ...has this minimal longhand equivalent...
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name => :authorised_caller_uuids
        #       }
        #     } )
        #
        # This leads to SQL along the following lines:
        #
        #    AND ("model_table"."creating_caller_uuid" IN ('[val]'))
        #
        # ...where <tt>val</tt> is from the Session +authorised_caller_uuids+
        # data in the +scoping+ section (so this might be an SQL +IN+ rather
        # than <tt>=</tt> if that data is a multi-element array). Suppose you
        # need to change this to check that value _or_ something else? Use the
        # +:using+ key and a Proc. Since ActiveRecord at the time of writing
        # lacks a high level way to do 'OR' via methods, it's easiest and most
        # flexible just to give up and fall to an SQL string:
        #
        #     or_matcher = Proc.new do | model_class, database_column_name, session_field_value |
        #
        #       # This example works for non-array and array field values.
        #       #
        #       session_field_value = [ session_field_value ].flatten
        #
        #       [
        #         "\"#{ database_column_name }\" IN (?) OR \"other_column_name\" IN (?)",
        #         session_field_value,
        #         session_field_value
        #       ]
        #     end
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name => :authorised_caller_uuids,
        #         :using              => or_matcher
        #       }
        #     } )
        #
        # ...yields something like:
        #
        #     AND ( "model_table"."creating_caller_uuid" IN ('[val]') OR "model_table"."other_column_name" IN ('[val]') )
        #
        # A Proc specified with +:using+ is called with:
        #
        # * The model class which is involved in the query.
        #
        # * The name of the database column specified in the +secure_with+
        #   Hash as the top-level key (e.g. +creating_called_uuid+ above).
        #
        # * The session field _value_ that was recovered under the given key -
        #   the value of +session.scoping.authorised_caller_uuids+ in the
        #   example above.
        #
        # You must return _AN ARRAY_ of arguments that will be passed to
        # +where+ via <tt>where( *returned_values )</tt> as part of the wider
        # query chain.
        #
        # == Security exemptions
        #
        # Sometimes you might want a security bypass mechanism for things like
        # a Superuser style caller that can "see everything". It's more secure,
        # where possible and scalable, to simply have the session data match
        # every known value of some particular secured-with quantity, but this
        # might get unwieldy. "WHERE IN" queries with hundreds or thousands of
        # listed items can cause problems!
        #
        # Noting that with any security exemption there is elevated risk, you
        # can use the +:exemptions+ key to provide a Proc which is passed the
        # secure value(s) under consideration (the data taken directly from
        # the session scoping section) and evaluates to +true+ if the value(s)
        # indicate that a security exemption applies, else evaluates "falsey"
        # for normal behaviour. We say "value(s)" here as a single key used to
        # read from the scoping section of a session may yield either a simple
        # value such as a String, or an Enumerable object such as an array of
        # many Strings.
        #
        # If the Proc evaluates to +true+, the result is no modification to the
        # secure scope chain being constructed for the secured ActiveRecord
        # query the caller will eventually run. Helper methods which construct
        # common use case Procs are present in
        # Hoodoo::ActiveRecord::Secure::SecurityHelper and there are
        # convenience constants defined in Hoodoo::ActiveRecord::Secure, such
        # as Hoodoo::ActiveRecord::Secure::ENUMERABLE_INCLUDES_STAR.
        #
        # Taking an earlier example:
        #
        #     secure_with( {
        #       :creating_caller_uuid => :authorised_caller_uuids
        #     } )
        #
        #     # ...has this minimal longhand equivalent...
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name => :authorised_caller_uuids
        #       }
        #     } )
        #
        # ...which leads to SQL along the following lines:
        #
        #    AND ("model_table"."creating_caller_uuid" IN ('[val]'))
        #
        # ...then suppose we wanted to allow a session scoping value of '*'
        # bypass security ("see everything"). We could use the
        # Enumerable-includes-star matcher Proc
        # Hoodoo::ActiveRecord::Secure::ENUMERABLE_INCLUDES_STAR here. At the
        # time of writing, it is defined as the following Proc:
        #
        #    Proc.new do | security_values |
        #      security_values.is_a?( Enumerable ) &&
        #      security_values.include?( '*' ) rescue false
        #    end
        #
        # This is activated through the +:exemptions+ key:
        #
        #     secure_with( {
        #       :creating_caller_uuid => {
        #         :session_field_name => :authorised_caller_uuids,
        #         :exemptions         => Hoodoo::ActiveRecord::Secure::ENUMERABLE_INCLUDES_STAR
        #       }
        #     } )
        #
        # If the looked up value of the +authorised_caller_uuids+ attribute
        # in the prevailing Session scoping section data was ["1234"], then the
        # SQL query additions would occur as above:
        #
        #    AND ("model_table"."creating_caller_uuid" IN ('1234'))
        #
        # ...but if there is a value of "*", the security layer will ignore the
        # normal restrictions, resulting in no SQL additions whatsoever.
        #
        # Since a Proc is used to compare the data found in the session against
        # some wildcard, things like checking an array of values for some magic
        # bypass characters / key, using regular expression matching, or other
        # more heavyweight options are all possible. Remember, though, that all
        # of this comes at a risk, since the mechanism is bypassing the normal
        # scope chain security. If used improperly or somehow compromised, it
        # will allow data to be read by an API caller that should not have been
        # permitted to access it.
        #
        # See module Hoodoo::ActiveRecord::Secure::SecurityHelper for methods
        # to help with exemption Proc construction.
        #
        def secure( context )
          prevailing_scope = all() # "Model.all" -> returns anonymous scope
          extra_scope_map  = secured_with()

          unless extra_scope_map.nil?
            return none() if context.session.nil? || context.session.scoping.nil?

            extra_scope_map.each do | model_field_name, key_or_options |
              exemption_proc = nil
              params_proc    = DEFAULT_SECURE_PROC

              if key_or_options.is_a?( Hash )
                session_scoping_key = key_or_options[ :session_field_name ]
                exemption_proc      = key_or_options[ :exemptions ]
                params_proc         = key_or_options[ :using ] if key_or_options.has_key?( :using )
              else
                session_scoping_key = key_or_options
              end

              if context.session.scoping.respond_to?( session_scoping_key )
                security_value = context.session.scoping.send( session_scoping_key )

                if exemption_proc.nil? || exemption_proc.call( security_value ) != true
                  args = params_proc.call(
                    self,
                    model_field_name,
                    security_value
                  )
                  prevailing_scope = prevailing_scope.where( *args )
                end

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
