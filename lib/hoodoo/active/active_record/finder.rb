########################################################################
# File::    finder.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Support mixin for models subclassed from ActiveRecord::Base
#           providing enhanced find mechanisms for data retrieval,
#           especially +show+ and +list+ action handling.
# ----------------------------------------------------------------------
#           25-Nov-2014 (ADH): Created.
########################################################################

require 'hoodoo/active/active_record/search_helper'

module Hoodoo
  module ActiveRecord

    # Mixin for models subclassed from ActiveRecord::Base providing support
    # methods to handle common +show+ and +list+ filtering actions based on
    # inbound data and create instances in a request context aware fashion.
    #
    # It is _STRONGLY_ _RECOMMENDED_ that you use the likes of:
    #
    # * Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in
    # * Hoodoo::ActiveRecord::Finder::ClassMethods#list_in
    #
    # ...to retrieve model data related to resource instances and participate
    # "for free" in whatever plug-in ActiveRecord modules are mixed into the
    # model classes, such as Hoodoo::ActiveRecord::Secure.
    #
    # See also:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    # Dependency Hoodoo::ActiveRecord::Secure is included automatically.
    #
    module Finder

      # Instantiates this module when it is included.
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Finder
      #       # ...
      #     end
      #
      # Depends upon and auto-includes Hoodoo::ActiveRecord::Secure.
      #
      # +model+:: The ActiveRecord::Base descendant that is including
      #           this module.
      #
      def self.included( model )
        model.class_attribute(
          :nz_co_loyalty_hoodoo_show_id_fields,
          :nz_co_loyalty_hoodoo_show_id_substitute,
          :nz_co_loyalty_hoodoo_estimate_counts_with,
          :nz_co_loyalty_hoodoo_search_with,
          :nz_co_loyalty_hoodoo_filter_with,
          {
            :instance_predicate => false,
            :instance_accessor  => false
          }
        )

        unless model == Hoodoo::ActiveRecord::Base
          model.send( :include, Hoodoo::ActiveRecord::Secure )
          instantiate( model )
        end

        super( model )
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

        framework_data = Hoodoo::ActiveRecord::Support.framework_search_and_filter_data()

        model.nz_co_loyalty_hoodoo_search_with ||= {}
        model.nz_co_loyalty_hoodoo_filter_with ||= {}

        model.nz_co_loyalty_hoodoo_search_with.merge!( framework_data )
        model.nz_co_loyalty_hoodoo_filter_with.merge!( framework_data )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Finder::included.
      #
      module ClassMethods

        # Returns an ActiveRecord::Relation instance representing a primitive
        # base scope that includes various context-related aspects according
        # to the prevailing mixins included by "this" class, if any - e.g.
        # security, dating and/or translation.
        #
        # See Hoodoo::ActiveRecord::Support#full_scope_for to see the list
        # of things that get included. If there are no "interesting" mixins,
        # the returned scope will just return the same thing that the +all+
        # method in ActiveRecord would have returned. Consequently, a default
        # scope _will_ be honoured if one has been declared, though default
        # scopes are generally considered an anti-pattern to be avoided.
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        def scoped_in( context )
          Hoodoo::ActiveRecord::Support.full_scope_for( self, context )
        end

        # As #scoped_in, but intentionally omits any historical dating modules
        # from the returned scope. The scope might then address both historic
        # and contemporary records, depending on whether you are using manual
        # or automatic dating.
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # See also:
        #
        # * Hoodoo::ActiveRecord::Dated
        # * Hoodoo::ActiveRecord::ManuallyDated
        #
        def scoped_undated_in( context )
          Hoodoo::ActiveRecord::Support.add_undated_scope_to(
            self.all(), # "all" -> returns anonymous scope
            self,
            context
          )
        end

        # "Polymorphic" find - support for finding a model by fields other
        # than just +:id+, based on a single unique identifier. Use #acquire
        # just like you'd use +find_by_id+ and only bother with it if you
        # support finding a resource instance by +id+ _and_ one or more
        # other model fields. Otherwise, just use +find_by_id+.
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
        #       return context.response.not_found( context.request.ident ) if found.nil?
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
        # This can only be used <i>if your searched fields are strings</i> in
        # the database. This includes, for example, the +id+ column; Hoodoo
        # usually expects to be a string field holding a 32-character UUID. If
        # any of the fields contain non-string types, attempts to use the
        # #acquire mechanism (or a related one) may result in database errors
        # due to type mismatches, depending upon the database engine in use.
        #
        # In more complex scenarious, you can just call #acquire at the end
        # of any chain of AREL queries just as you would call ActiveRecord's
        # own #find_by_id method, e.g.:
        #
        #     SomeModel.where( :foo => :bar ).acquire( context.request.ident )
        #
        # Usually for convenience you should use #acquire_in_and_update or
        # acquire_in instead, or only call #acquire with (say) a secure scope
        # via for example a call to
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure. Other scopes may
        # be needed depending on the mixins your model uses.
        #
        # +ident+:: The value to search for in the fields (attributes)
        #           specified via #acquire_with, matched using calls to
        #           <tt>where( attr => ident )</tt>.
        #
        # Returns a found model instance or +nil+ for no match.
        #
        def acquire( ident )
          return acquisition_scope( ident ).first
        end

        # Implicily secure, translated, dated etc. etc. version of #acquire,
        # according to which modules are mixed into your model class. Uses
        # #scoped_in to obtain a base scope in which to operate, so it is
        # "mixin aware" and incorporates other Hoodoo extensions within the
        # wider scope chain. See that method's documentation for more
        # information.
        #
        # For example, if you are using or at some point intend to mix in and
        # use the mechanism described by the likes of
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure, call here as a
        # convenience to both obtain a secure context and find a record
        # (with or without additional find-by fields other than +id+) in one
        # go. Building on the example from
        # Hoodoo::ActiveRecord::Secure::ClassMethods#secure, we might have an
        # Audit model as follows:
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
        #       return context.response.not_found( context.request.ident ) if found.nil?
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
        # The same applies to forgetting dated scopes, translated scopes, or
        # anything else that #scoped_in might include for you.
        #
        # An even higher-level method, taking care of error handling as well,
        # is #acquire_in_and_update. You may prefer to call this higher level
        # interface if you don't object to the way it modifies +context+.
        #
        # Parameters:
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # See also:
        #
        # * Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in_and_update
        # * Hoodoo::Services::Response#not_found
        # * Hoodoo::Services::Response#contemporary_exists
        #
        # Returns a found model instance or +nil+ for no match / on error.
        #
        def acquire_in( context )
          scoped_in( context ).acquire( context.request.ident )
        end

        # A higher level equivalent of #acquire_in in which the given context
        # will be updated with error information if the requested item cannot
        # be found. Although modifying the passed-in context may be considered
        # an unclean pattern, it does allow extensions to that mechanism. For
        # example, in the presence of the Hoodoo::ActiveRecord::Dated or
        # Hoodoo::ActiveRecord::ManuallyDated modules, an additional error
        # entry of +generic.contemporary_exists+ will be added if conditions
        # warrant it.
        #
        # At the time of writing only this and/or +generic.not_found+ can be
        # added, but in future other mixin modules may cause other additions,
        # making preferential use of this method over #acquire_in a good way
        # to future-proof against such changes.
        #
        # To be sure that these additions work, always include this module
        # before any others (unless documentation indicates a differing
        # inclusion order requirement), so that the dating module is able to
        # detect the presence of this Finder module and enable the extensions.
        #
        # Parameters:
        #
        # +context+:: Hoodoo::Services::Context instance describing a call
        #             context. This is typically a value passed to one of
        #             the Hoodoo::Services::Implementation instance methods
        #             that a resource subclass implements.
        #
        # See also:
        #
        # * Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in
        # * Hoodoo::Services::Response#not_found
        # * Hoodoo::Services::Response#contemporary_exists
        #
        # Returns a found model instance or +nil+ for no match / on error,
        # wherein +context+ will have been updated with error details.
        #
        # Example, following on from those for #acquire_in:
        #
        #     def show( context )
        #       resource = SomeModel.acquire_in_and_update( context )
        #       return if context.response.halt_processing? # Or just use 'if resource.nil?'
        #
        #       # ...else render...
        #     end
        #
        def acquire_in_and_update( context )

          # The method is patched internally by Hoodoo::ActiveRecord::Dated
          # and Hoodoo::ActiveRecord::ManuallyDated. The patches add in a
          # +generic.contemporary_exists+ error using appropriate checks for
          # a contemporary record, where necessary. This way, any performance
          # overhead that might be introduced by the added code is only
          # present when a class uses one of the dating modules.
          #
          # It's an internal patch and not intended for additional external
          # changes, so it does not use the public "monkey_" naming prefix.

          result = acquire_in( context )
          context.response.not_found( context.request.ident ) if result.nil?

          return result
        end

        # Describe the list of model fields _in_ _addition_ _to_ +id+ which
        # are to be used to "find-by-identifier" through calls #acquire,
        # #acquire_in and #acquire_in_and_update. See those methods for more
        # details.
        #
        # Fields will be searched in the order listed. If duplicate items are
        # present, the first occurrence is kept and the rest are removed.
        #
        # *args:: One or more field names as Strings or Symbols.
        #
        # See also:
        #
        # * #acquired_with
        # * #acquire_with_id_substitute
        #
        def acquire_with( *args )
          self.nz_co_loyalty_hoodoo_show_id_fields = args.map( & :to_s )
          self.nz_co_loyalty_hoodoo_show_id_fields.uniq!()
        end

        # Return the list of model fields _in_ _addition_ _to_ +id+ which
        # are being used to "find-by-identifier" through calls to #acquire,
        # #acquire_in and #acquire_in_and_update. The returned Array contains
        # de-duplicated String values only.
        #
        # See also:
        #
        # * #acquire_with
        # * #acquire_with_id_substitute
        #
        def acquired_with
          self.nz_co_loyalty_hoodoo_show_id_fields || []
        end

        # The #acquire_with method allows methods like #acquire, #acquire_in
        # and #acquire_in_and_update to transparently find a record based on
        # _one_ _or_ _more_ columns in the database. The columns (and
        # corresponding model attributes) specified through a call to
        # #acquire_with will normally be used _in_ _addition_ _to_ a lookup on
        # the +id+ column, but in rare circumstances you might need to bypass
        # that and use an entirely different field. This is distinct from the
        # ActiveRecord-level concept of the model's primary key column.
        #
        # To permanently change the use of the +id+ attribute as the first
        # search parameter in #acquire, #acquire_in and #acquire_in_and_update
        # by modifying the behaviour of #acquisition_scope, call here and pass
        # in the new attribute name.
        #
        # +attr+:: Attribute name as a Symbol or String to use _instead_
        #          of +id+, as a default mandatory column in
        #          #acquisition_scope.
        #
        def acquire_with_id_substitute( attr )
          self.nz_co_loyalty_hoodoo_show_id_substitute = attr.to_sym
        end

        # Back-end to #acquire and therefore, in turn, #acquire_in and
        # #acquire_in_and_update. Returns an ActiveRecord::Relation instance
        # which scopes the search for a record by +id+ and across any other
        # columns specified by #acquire_with, via SQL +OR+.
        #
        # If you need to change the use of attribute +id+, specify a
        # different attribute with #acquire_with_id_substitute. In that case,
        # the given attribute is searched for instead of +id+; either way, a
        # default starting attribute _will_ be used in scope in addition to
        # any extra fields specified using #acquire_with.
        #
        # Normally such a scope could only ever return a single record based
        # on an assuption of uniqueness constraints around columns which one
        # might use in an equivalent of a +find+ call. This scope is often
        # chained on top of a wider listing scope provided by #scoped_in to
        # create a fully context-aware, secure, dated, translated etc. query.
        # It is possible however that the chosen +ident+ value might not
        # resolve to a single unique record depending on how your data works
        # and you may need to manually apply additional constraints to the
        # returned ActiveRecord::Relation instance.
        #
        def acquisition_scope( ident )
          extra_fields = self.acquired_with()
          arel_table   = self.arel_table()
          arel_query   = arel_table[ self.nz_co_loyalty_hoodoo_show_id_substitute || :id ].eq( ident )

          extra_fields.each do | field |
            arel_query = arel_query.or( arel_table[ field ].eq( ident ) )
          end

          return where( arel_query )
        end

        # Generate an ActiveRecord::Relation instance which can be used to
        # count, retrieve or further refine a list of model instances from
        # the database.
        #
        # Usually for convenience you should use #list_in instead, or only
        # call #acquire with (say) a secure scope via for example a call to
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
        # amount of results in the dataset without pagination. A resource may
        # alternatively choose to use #estimated_dataset_size for a fast count
        # estimation, or neither (though this is generally not recommended) or
        # - permissible but unusual - include both.
        #
        #     context.response.set_resources( results, nil, finder.estimated_dataset_size )
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
          finder = finder.order( list_parameters.sort_data )

          search_map = self.nz_co_loyalty_hoodoo_search_with

          unless search_map.nil?
            search_map.each do | attr, finder_args_proc |
              value = list_parameters.search_data[ attr ]
              next if value.nil?

              args   = finder_args_proc.call( attr, value )
              finder = finder.where( *args ) unless args.nil?
            end
          end

          filter_map = self.nz_co_loyalty_hoodoo_filter_with

          unless filter_map.nil?
            filter_map.each do | attr, finder_args_proc |
              value = list_parameters.filter_data[ attr ]
              next if value.nil?

              args   = finder_args_proc.call( attr, value )
              finder = finder.where.not( *args ) unless args.nil?
            end
          end

          return finder
        end

        # Implicily secure, translated, dated etc. etc. version of #list,
        # according to which modules are mixed into your model class. See
        # #scoped_in to see the list of things that get included in the
        # scope according to the mixins that are in use.
        #
        # For example, if you have included Hoodoo::ActiveRecord::Secure,
        # this method provides you with an implicitly secure query. Read the
        # documentation on #acquire_in versus #acquire for information
        # on the use of secure scopes; as with #acquire_in and the "Secure"
        # mixin, this method becomes for convenience and safety - you
        # can't accidentally forget the secure scope:
        #
        #     SomeModel.secure( context ).list( context.request.list )
        #
        #     # ...has the same result as...
        #
        #     SomeModel.list_in( context )
        #
        # The same applies to forgetting dated scopes, translated scopes, or
        # anything else that #scoped_in might include for you.
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
          return scoped_in( context ).list( context.request.list )
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
          return all.limit( nil ).offset( nil ).count()
        end

        # As #dataset_size, but allows a configurable counting back-end via
        # #estimated_count and #estimate_counts_with. This method is intended
        # to be used for fast count estimations, usually for performance
        # reasons if an accurate #dataset_size count is too slow to compute.
        #
        def estimated_dataset_size
          return all.limit( nil ).offset( nil ).estimated_count()
        end

        # In absence of other configuration, this method just calls through
        # to Active Record's #count, but you can override the counting
        # mechanism with a Proc which gets called to do the counting instead.
        #
        # The use case is for databases where counting may be slow for some
        # reason. For example, in PostgreSQL 9, the MVCC model means that big
        # tables under heavy write load may take extremely long times to be
        # counted as a full sequential row scan gets activated. In the case
        # of PostgreSQL, there's an estimation available as an alternative;
        # its accuracy depends on how often the +ANALYZE+ command is run, but
        # at least its execution speed is always very small.
        #
        # The #estimated_dataset_size method runs through here for counting so
        # you need to ensure that your count estimation method can cope with
        # whatever queries that might arise from the scope chains involved in
        # instances of the model at hand, within the service code that uses
        # that model.
        #
        # Specify a count estimation Proc with #estimate_counts_with. Such
        # blocks are permitted to return +nil+ if the estimation is considered
        # to be wildly wrong or unobtainable; in that case, the returned value
        # for the estimated count will be +nil+ too.
        #
        def estimated_count
          counter = self.nz_co_loyalty_hoodoo_estimate_counts_with

          if ( counter.nil? )
            return all.count
          else
            return counter.call( all.to_sql )
          end
        end

        # This method is related to #estimated_count, so read the documentation
        # for that as an introduction first.
        #
        # In #estimated_count, a PostgreSQL example is given. Continuing with
        # this, we could implement an estimation mechanism via Hoodoo's fast
        # counter with something like the approach described here:
        #
        # * https://wiki.postgresql.org/wiki/Count_estimate
        # * http://www.verygoodindicators.com/blog/2015/04/07/faster-count-queries/
        #
        # First, you would need a migration in your service to implement the
        # estimation method as a PLPGSQL function:
        #
        #     class CreateFastCountFunction < ActiveRecord::Migration
        #       def up
        #         execute <<-SQL
        #           CREATE FUNCTION estimated_count(query text) RETURNS integer AS
        #           $func$
        #           DECLARE
        #               rec   record;
        #               rows  integer;
        #           BEGIN
        #               FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
        #                   rows := substring(rec."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
        #                   EXIT WHEN rows IS NOT NULL;
        #               END LOOP;
        #
        #               RETURN rows;
        #           END
        #           $func$ LANGUAGE plpgsql;
        #         SQL
        #       end
        #
        #       def down
        #         execute "DROP FUNCTION estimated_count(query text);"
        #       end
        #     end
        #
        # This takes arbitrary query text so should cope with pretty much any
        # kind of ActiveRecord query chain and resulting SQL. Run the database
        # migration, then define a Proc which calls the new function:
        #
        #     counter = Proc.new do | sql |
        #       begin
        #         sql = sql.gsub( "'", "''" ) # Escape SQL for insertion below
        #         ActiveRecord::Base.connection.execute(
        #           "SELECT estimated_count('#{ sql }')"
        #         ).first[ 'estimated_count' ].to_i
        #       rescue
        #         nil
        #     end
        #
        # Suppose we have a model called +Purchase+; next tell this model to
        # use the above Proc for fast counting and use it:
        #
        #     Purchase.estimate_counts_with( counter )
        #
        #     Purchase.estimated_count()
        #     # => An integer; and you can use scope chains, just like #count:
        #     Purchase.where(...conditions...).estimated_count()
        #     # => An integer
        #
        # A real-life example showing how running PostgreSQL's +ANALYZE+
        # command can make a difference:
        #
        #     [1] pry(main)> Purchase.estimated_count
        #     => 68
        #     [2] pry(main)> Purchase.count
        #     => 76
        #     [3] pry(main)> ActiveRecord::Base.connection.execute( 'ANALYZE' )
        #     => #<PG::Result:0x007f89b62cdcc8 status=PGRES_COMMAND_OK ntuples=0 nfields=0 cmd_tuples=0>
        #     [4] pry(main)> Purchase.estimated_count
        #     => 76
        #
        # Parameters:
        #
        # +proc+:: The Proc to call. It must accept one parameter, which is the
        #          SQL query for which the count is to be run, as a String. It
        #          must evaluate to an Integer estimation, or +nil+ if it is
        #          not able to provide any/useful estimations, in its opinion.
        #
        #          Pass +nil+ to remove the custom counter method and restore
        #          default behaviour.
        #
        def estimate_counts_with( proc )
          self.nz_co_loyalty_hoodoo_estimate_counts_with = proc
        end

        # Specify a search mapping for use by #list to automatically restrict
        # list results.
        #
        # In the simplest case, search query string entries and model field
        # (attribute) names are assumed to be the same; if you wanted to
        # search for values of model attributes +name+ and +colour+ using
        # query string entries of +name+ and +colour+ you would just do this:
        #
        #     class SomeModel < ActiveRecord::Base
        #       search_with(
        #         :name   => nil,
        #         :colour => nil
        #       )
        #     end
        #
        # The +nil+ values mean a default, case sensitive match is performed
        # with the query string keys and values mapping directly to model
        # query attribute names and values.
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
        # To help out with common cases other than just specifying +nil+, the
        # Hoodoo::ActiveRecord::Finder::SearchHelper class provides a method
        # chaining approach which builds up the Hash used by #search_with and
        # filter_with. See that class's API documentation for details.
        #
        # *args:: A Hash. Keys are both search field names and model attribute
        #         names, unless overridden by values; values of +nil+ are used
        #         for simple cases - "where( { attr_name => value } )" will be
        #         the resulting query modification. Alternatively, pass a
        #         callable Proc/Lambda. This is pased the attribute under
        #         consideration (and so you can ignore that and query against
        #         one or more different-named model attributes) and the
        #         context-caller-supplied value to search for. Return *AN*
        #         *ARRAY* of parameters to pass to +where+. For parameters to
        #         +where+, see:
        #
        #         http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where
        #
        #         The Hash keys giving the search attribute names can be
        #         specified as Strings or Symbols.
        #
        #         See Hoodoo::ActiveRecord::Finder::SearchHelper for methods
        #         which assist with filling in non-nil values for this Hash.
        #
        def search_with( hash )
          self.nz_co_loyalty_hoodoo_search_with.merge!( Hoodoo::ActiveRecord::Support.process_to_map( hash ) )
        end

        # As #search_with, but used in +where.not+ queries.
        #
        # <b><i>IMPORTANT:</i></b> Beware +null+ column values and filters
        # given SQL's strange behaviour with such things. The search helpers
        # in Hoodoo::ActiveRecord::Finder::SearchHelper class will work as
        # logically expected ("field not 'foo'" will find fields with a null
        # value), though if you're expecting SQL-like behaviour it might come
        # as a surprise! Using <tt>...AND field IS NOT NULL</tt> in queries
        # for +filter_with+ tends to work reasonably when the query is
        # negated for filter use via <tt>...NOT(...)...</tt>. Examining the
        # implementation of Hoodoo::ActiveRecord::Finder::SearchHelper may
        # help if confused.
        #
        # See also:
        #
        # * https://en.wikipedia.org/wiki/Null_(SQL)
        #
        # +map+:: As #search_with.
        #
        def filter_with( hash )
          self.nz_co_loyalty_hoodoo_filter_with.merge!( Hoodoo::ActiveRecord::Support.process_to_map( hash ) )
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
