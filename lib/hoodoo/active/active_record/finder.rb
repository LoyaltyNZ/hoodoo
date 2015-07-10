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
    # support methods to handle common +show+ and +list+ filtering actions
    # based on inbound data.
    #
    # Requires Hoodoo::ActiveRecord::Secure, which is automatically included
    # if necessary.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Finder

      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Finder
      #       # ...
      #     end
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        unless model == Hoodoo::ActiveRecord::Base
          model.send( :include, Hoodoo::ActiveRecord::Secure )
          instantiate( model )
        end
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Finder::ClassMethods methods are defined as
      # class methods on the including class.
      #
      # This module depends upon Hoodoo::ActiveRecord::Secure, so that
      # will be auto-included first if it isn't already.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Finder::included.
      #
      module ClassMethods

        # "Polymorphic" find - support for finding a model by fields other
        # than just +:id+, based on a single unique identifier. Use #acquire
        # just like you'd use +find_by_id+ and only bother with it if you
        # support finding a resource instance by +id+ _and_ one or more
        # other model fields. Otherwise, just use +find_by_id+.
        #
        # For secured data access, use #acquire_in instead, or only call
        # #acquire with a secure scope from e.g. a call to
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure.
        #
        # In the model, you declare the list of fields _in_ _addition_ _to_
        # +id+ by calling #acquire_with thus:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Finder
        #       acquire_with ... # <list-of-other-fields>
        #     end
        #
        # For example, maybe you allow some resource to be looked up by fields
        # +id+ or +code+, both of which are independently unique sets. Since
        # +id+ is always automatically included, you only need to do this:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Finder
        #       acquire_with :code
        #     end
        #
        # Then, in a resource's implementation:
        #
        #     def show( context )
        #       found = SomeModel.acquire( context.request.ident )
        #       return context.response.not_found() if found.nil?
        #
        #       # ...map 'found' to whatever resource you're representing,
        #       # e.g. via a Hoodoo::Presenters::Base subclass with resource
        #       # schema and the subclass's Hoodoo::Presenters::Base::render
        #       # call, then...
        #
        #       context.response.set_resource( resource_representation_of_found )
        #     end
        #
        # There is nothing magic "under the hood" - Hoodoo just tries to
        # find records with a value matching the incoming identifier for
        # each of the fields in turn. It starts with +id+ then runs through
        # any other fields in the order given through #acquire_with.
        #
        # In more complex scenarious, you can just call #acquire at the end
        # of any chain of AREL queries just as you would call ActiveRecord's
        # own #find_by_id method, e.g.:
        #
        #     SomeModel.where( :foo => :bar ).acquire( context.request.ident )
        #
        # +ident+:: The value to search for in the fields (attributes)
        #           specified via #acquire_with, matched using calls to
        #           <tt>where( attr => ident )</tt>.
        #
        # Returns a found model instance or +nil+ for no match.
        #
        def acquire( ident )
          extra_fields = class_variable_defined?( :@@nz_co_loyalty_hoodoo_show_id_fields ) ?
                              class_variable_get( :@@nz_co_loyalty_hoodoo_show_id_fields ) :
                              nil

          id_fields = [ :id ] + ( extra_fields || [] )
          id_fields.each do | field |

            # This is fiddly.
            #
            # You must use a string with field substitution approach, rather
            # than e.g. ".where( :field => :ident )". AREL/ActiveRecord will,
            # in the latter case, compose rational SQL based on column data
            # types. If you have an *integer* ID field, then, it'll try to
            # convert a *string* ident to an integer. This can give Hilarious
            # Consequences. Consider looking up on (integer) field "id" or
            # (text) field "uuid", with a string ident of "1f294942..." - the
            # text UUID would be fine, but the integer ID may end up with the
            # UUID being "to_i"'d, yielding integer 1. If the ID field is
            # looked at first, you're highly likely to find the wrong record.
            #
            # The solution is, as written, simple; just use the substitution
            # approach rather than higher level AREL, causing a string-like SQL
            # query on all adapters which SQL handles just fine for varying
            # field data types.
            #
            # # TODO document weirdness around different types for identifier
            # fields (can have one type only, not string and integer)

            checker = where( [ "\"#{ self.table_name }\".\"#{ field }\" = ?", ident ] )
            return checker.first unless checker.count == 0
          end

          return nil
        end

        # Implicily secure version of #acquire.
        #
        # Assuming you are using or at some point intend to use the
        # mechanism described by
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure, call here as a
        # convenience to both obtain a secure context and find a record
        # (with or without additional find-by fields other than +id+) in one
        # go. Building on the example from
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure, we might have
        # an Audit model as follows:
        #
        #     class Audit < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Secure
        #
        #       secure_with( {
        #         :creating_caller_uuid => :authorised_caller_uuid
        #       } )
        #
        #       # Plus perhaps a call to "acquire_with"
        #     end
        #
        # Then, in a resource's implementation:
        #
        #     def show( context )
        #       found = SomeModel.acquire_in( context )
        #       return context.response.not_found() if found.nil?
        #
        #       # ...map 'found' to whatever resource you're representing,
        #       # e.g. via a Hoodoo::Presenters::Base subclass with resource
        #       # schema and the subclass's Hoodoo::Presenters::Base::render
        #       # call, then...
        #
        #       context.response.set_resource( resource_representation_of_found )
        #     end
        #
        # The value of +found+ will be acquired within the secure context
        # determined by the prevailing call context (and its session), so
        # the data it finds is inherently correctly scoped - provided your
        # model's Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with
        # call describes things correctly.
        #
        # This method is for convenience and safety - you can't accidentally
        # forget the secure scope:
        #
        #     SomeModel.secure( context ).acquire( context.request.ident )
        #
        #     # ...has the same result as...
        #
        #     SomeModel.acquire_in( context )
        #
        # Parameters:
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # Returns a found model instance or +nil+ for no match.
        #
        def acquire_in( context )
          return secure( context ).acquire( context.request.ident )
        end

        # Describe the list of model fields _in_ _addition_ _to_ +id+ which
        # are to be used to "find-by-identifier" through calls #acquire and
        # #acquire_in. See those for more details.
        #
        # *args:: One or more field names as Strings or Symbols.
        #
        def acquire_with( *args )
          class_variable_set( '@@nz_co_loyalty_hoodoo_show_id_fields', args )
        end

        # Generate an ActiveRecord::Relation instance which can be used to
        # count, retrieve or further refine a list of model instances from
        # the database.
        #
        # For secured data access, use #list_in instead, or only call
        # #acquire with a secure scope from e.g. a call to
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure. An example of
        # this second option is shown below.
        #
        # Pass a Hoodoo::Services::Request::ListParameters instance, e.g.
        # via the Hoodoo::Services::Context instance passed to resource
        # endpoint implementations and accessor +context.request.list+. It
        # takes into account the list offset, limit, sort key and sort
        # direction automatically. In addition, it can do simple search and
        # filter operations if search and filter mappings are set up via
        # #search_with and #filter_with.
        #
        # For exampe, in a simple case where a model can be listed without
        # any unusual constraints, we might do this:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Finder
        #
        #       search_with # ...<field-to-search-info mapping>
        #       # ...and/or...
        #       filter_with # ...<field-to-search-info mapping>
        #     end
        #
        #     # ...then, in the resource implementation...
        #
        #     def list( context )
        #       finder = SomeModel.list( context.request.list )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.set_resources( results, finder.dataset_size )
        #     end
        #
        # Note the use of helper method #dataset_size to count the total
        # amount of results in the dataset without pagination.
        #
        # The service middleware enforces sane values for things like list
        # offsets, sort keys and so-on according to service interface
        # definitions, so if using the middleware you don't need to do any
        # extra checking yourself.
        #
        # Since the returned object is just a relation, adding further
        # constraints is easy - call things like +where+, +group+ and so-on
        # as normal. You can also list in a secure context via the included
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure, assuming
        # appropriate data is set in the model via
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with:
        #
        #     def list( context )
        #       finder = SomeModel.secure( context ).list( context.request.list )
        #       finder = finder.where( :additional_filter => 'some value' )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.set_resources( results, finder.dataset_size )
        #     end
        #
        # Since it's just a chained scope, you can call in any order:
        #
        #     SomeModel.secure( context ).list( context.request.list )
        #
        #     # ...has the same result as...
        #
        #     SomeModel.list( context.request.list ).secure( context )
        #
        # Any of the ActiveRecord::QueryMethods can be called on the returned
        # value. See:
        #
        # http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html
        #
        # +list_parameters+:: Hoodoo::Services::Request::ListParameters
        #                     instance, typically obtained from the
        #                     Hoodoo::Services::Context instance passed to
        #                     a service implementation in
        #                     Hoodoo::Services::Implementation#list, via
        #                     +context.request.list+ (i.e.
        #                     Hoodoo::Services::Context#request
        #                     / Hoodoo::Services::Request#list).
        #
        def list( list_parameters )
          finder = all.offset( list_parameters.offset ).limit( list_parameters.limit )
          finder = finder.order( { list_parameters.sort_key => list_parameters.sort_direction.to_sym } )

          # DRY up the 'each' loops below. Use a Proc not a method because any
          # methods we define will end up being defined on the including Model,
          # increasing the chance of a name collision.
          #
          dry_proc = Proc.new do | data, attr, proc |
            value = data[ attr.to_s ]
            next if value.nil?

            if ( proc.nil? )
              [ { attr => value } ]
            else
              proc.call( attr, value )
            end
          end

          search_map = class_variable_defined?( :@@nz_co_loyalty_hoodoo_search_with ) ?
                            class_variable_get( :@@nz_co_loyalty_hoodoo_search_with ) :
                            nil

          filter_map = class_variable_defined?( :@@nz_co_loyalty_hoodoo_filter_with ) ?
                            class_variable_get( :@@nz_co_loyalty_hoodoo_filter_with ) :
                            nil

          unless search_map.nil?
            search_map.each do | attr, proc |
              args   = dry_proc.call( list_parameters.search_data, attr, proc )
              finder = finder.where( *args ) unless args.nil?
            end
          end

          unless filter_map.nil?
            filter_map.each do | attr, proc |
              args   = dry_proc.call( list_parameters.filter_data, attr, proc )
              finder = finder.where.not( *args ) unless args.nil?
            end
          end

          return finder
        end

        # Implicily secure version of #list.
        #
        # Read the documentation on #acquire_in versus #acquire for information
        # on the use of secure scopes.
        #
        # As with #acquire_in, this method is for convenience and safety - you
        # can't accidentally forget the secure scope:
        #
        #     SomeModel.secure( context ).list( context.request.list )
        #
        #     # ...has the same result as...
        #
        #     SomeModel.list_in( context )
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # Returns a secure list scope, for either further modification with
        # query methods like +where+ or fetching from the database with +all+.
        #
        def list_in( context )
          return secure( context ).list( context.request.list )
        end

        # Given some scope - typically that obtained from a prior call to
        # #list or #list_in, with possibly other query modifiers too - return
        # the total dataset size. This is basically a +COUNT+ operation, but
        # run without offset or limit considerations (ignoring pagination).
        #
        # This is particularly useful if you are calling
        # Hoodoo::Services::Response#set_resources and want to fill in its
        # +dataset_size+ parameter.
        #
        def dataset_size
          return all.limit( nil ).offset( nil ).count
        end

        # Specify a search mapping for use by #list_finder to automatically
        # restrict list results.
        #
        # Simple example which just looks for verbatim field matches on
        # fields +name+ and +colour+:
        #
        #     class SomeModel < ActiveRecord::Base
        #       search_with(
        #         :name => nil,
        #         :colour => nil
        #       )
        #     end
        #
        # More complex example where +colour+ is matched verbatim, but +name+
        # is matched case-insensitive, assuming PostgreSQL's ILIKE is there:
        #
        #     class SomeModel < ActiveRecord::Base
        #       search_with(
        #         :name => Proc.new { | attr, value |
        #           [ 'name ILIKE ?', value ]
        #         },
        #         :colour => nil
        #       )
        #     end
        #
        # Extending the above to use a single Proc that handles case
        # insensitive matches across all attributes:
        #
        #     class SomeModel < ActiveRecord::Base
        #       CI_MATCH = Proc.new { | attr, value |
        #         [ "#{ attr } ILIKE ?", value ]
        #       }
        #
        #       search_with(
        #         :name   => CI_MATCH,
        #         :colour => CI_MATCH
        #       )
        #     end
        #
        # If you wanted to match against an array of possible matches, something
        # like this would work:
        #
        #     ARRAY_MATCH = Proc.new { | attr, value |
        #       [ { attr => [ value ].flatten } ]
        #     }
        #
        # Note the returned *array* (see input parameter details) inside which
        # the usual hash syntax for AREL +.where+-style queries is present.
        #
        # +map+:: A Hash. Keys are attribute names. Values of +nil+ are used
        #         for simple cases - "where( { attr_name => value } )" will be
        #         the resulting query modification. Alternatively, pass a
        #         callable Proc/Lambda. This is pased the attribute under
        #         consideration and the context-caller-supplied value to search
        #         on for that attribute. Return *AN* *ARRAY* of parameters to
        #         pass to +where+. For parameters to +where+, see:
        #
        #         http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where
        #
        #         The Hash keys giving the search attribute names can be
        #         specified as Strings or Symbols.
        #
        def search_with( map )
          class_variable_set( '@@nz_co_loyalty_hoodoo_search_with', map )
        end

        # As #search_with, but used in +where.not+ queries.
        #
        # +map+:: As #search_with.
        #
        def filter_with( map )
          class_variable_set( '@@nz_co_loyalty_hoodoo_filter_with', map )
        end

        # Deprecated interface replaced by #acquire. Instead of:
        #
        #     Model.polymorphic_find( foo, ident )
        #
        # ...use:
        #
        #     foo.acquire( ident )
        #
        # This implementation is for legacy support and just calls through
        # to #acquire.
        #
        # +finder+:: #acquire is called on this.
        #
        # +ident+::  Passed to #acquire.
        #
        # Returns a found model instance or +nil+ for no match.
        #
        def polymorphic_find( finder, ident )
          $stderr.puts( 'Hoodoo:ActiveRecord::Finder#polymorphic_find is deprecated - use "foo.acquire( ident )" instead of "Model.polymorphic_find( foo, ident )"' )
          finder.acquire( ident ) # Ignore 'finder'
        end

        # Deprecated interface replaced by #acquire_with (this is an alias).
        #
        # *args:: Passed to #acquire_with.
        #
        def polymorphic_id_fields( *args )
          $stderr.puts( 'Hoodoo:ActiveRecord::Finder#polymorphic_id_fields is deprecated - rename call to "#acquire_with"' )
          acquire_with( *args )
        end

        # Deprecated interface replaced by #list (this is an alias).
        #
        # +list_parameters+:: Passed to #list.
        #
        def list_finder( list_parameters )
          $stderr.puts( 'Hoodoo:ActiveRecord::Finder#list_finder is deprecated - rename call to "#list"' )
          return list( list_parameters )
        end

        # Deprecated interface replaced by #search_with (this is an alias).
        #
        # +map+:: Passed to #search_with.
        #
        def list_search_map( map )
          $stderr.puts( 'Hoodoo:ActiveRecord::Finder#list_search_map is deprecated - rename call to "#search_with"' )
          search_with( map )
        end

        # Deprecated interface replaced by #filter_with (this is an alias).
        #
        # +map+:: Passed to #filter_with.
        #
        def list_filter_map( map )
          $stderr.puts( 'Hoodoo:ActiveRecord::Finder#list_filter_map is deprecated - rename call to "#filter_with"' )
          filter_with( map )
        end
      end
    end
  end
end
