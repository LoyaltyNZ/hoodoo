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

module ApiTools
  module ActiveRecord

    # Support mixin for models subclassed from ActiveRecord::Base providing
    # support methods to handle common +show+ and +list+ filtering actions
    # based on inbound data. See:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Finder

      # When included into an ActiveRecord::Base subclass, all of the
      # ApiTools::ActiveRecord::Finder::ClassMethods methods are defined as
      # class methods on the including class.
      #
      def self.included( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # ApiTools::ActiveRecord::Finder::included.
      #
      module ClassMethods

        # "Polymorphic" find - support for finding a model by fields other than
        # just +:id+, based on a single unique identifier. The attributes to be
        # searched upon are specified via #polymorphic_id_fields; +:id+ is
        # always included as a lookup attribute and will be checked first.
        #
        # Pass an ActiveRecord::Relation instance or the model class itself as
        # the base finder, then the identifier. To explain this more - in the
        # simple case, you might just want to search across several fields for
        # a match against the identifier thus:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include ApiTools::ActiveRecord::Finder
        #     end
        #
        #     # ...elsewhere...
        #
        #     def show( context )
        #       found = SomeModel.polymorphic_find( SomeModel, context.request.ident )
        #       # ...
        #     end
        #
        # More often, though, you might want to restrict the search to model
        # instances matching certain fields, perhaps for security reasons.
        # Maybe caller authoristion layers provide a session with a +client_id+
        # and you implicitly only allow lookups for instances owned by that
        # client, through storing the value with the model in a field of the
        # same name.
        #
        #     def show( context )
        #       finder = SomeModel.where( :client_id => context.session.client_id )
        #       found = SomeModel.polymorphic_find( finder, context.request.ident )
        #       # ...
        #     end
        #
        # +finder+:: An ActiveRecord::Base subclass or ActiveRecord::Relation
        #            instance - something that the likes of +where+ can be
        #            sent to, as part of building up a query chain; the
        #            ActiveRecord::QueryMethods must be supported.
        #
        #            http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html
        #
        # +ident+::  The value to search for in the fields (attributes)
        #            specified via #polymorphic_id_fields, using
        #            +where( attr => ident )+.
        #
        # Returns a found model instance or +nil+ for no match.
        #
        def polymorphic_find( finder, ident )
          extra_fields = class_variable_get( '@@nz_co_loyalty_show_id_fields' ) || []
          id_fields    = [ :id ] + extra_fields

          id_fields.each do | field |
            checker = finder.where( field => ident )
            return checker.first unless checker.count == 0
          end

          return nil
        end

        # Specify the fields (attributes / columns) upon which
        # #polymorphic_find will perform its search. +:id+ is included by
        # default always and does not need specifying.
        #
        # For example, if a model supported looking up via a UUID in the
        # +:id+ attribute or through a secondary unique identifier in the
        # +:code+ attribute, then declare the situation thus:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include ApiTools::ActiveRecord::Finder
        #       polymorphic_id_fields :code
        #     end
        #
        # ...and find records via #polymorphic_find.
        #
        # *args:: One or more fields (attributes), as Symbols.
        #
        def polymorphic_id_fields( *args )
          class_variable_set( '@@nz_co_loyalty_show_id_fields', args )
        end

        # Generate an ActiveRecord::Relation instance which can be used to
        # count, retrieve or further refine a list of model instances from the
        # database.
        #
        # The returned relation is generated via a given instance of
        # ApiTools::ServiceContext. It takes into account the context's
        # ApiTools::ServiceRequest and the list offset, list limit, list sort
        # key and list sort direction automatically. In addition, it can do
        # simple search and filter operations if search and filter mappings
        # are set up via #list_search_map and #list_filter_map.
        #
        # For exampe, in a simple case where a model can be listed without any
        # unusual constraints, we might do this:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include ApiTools::ActiveRecord::Finder
        #     end
        #
        #     # ...elsewhere...
        #
        #     def list( context )
        #       finder = SomeModel.list_finder( context )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.body = results
        #     end
        #
        # (Bear in mind that the service middleware enforces sane values for
        # things like list offsets, sort keys and so-on according to service
        # interface definitions, so if using the middleware you don't need to
        # do any extra checking).
        #
        # Since the returned object is just a relation, adding further
        # constraints is easy - call things like +where+, +group+ and so-on as
        # normal. For example, suppose caller authoristion layers provide a
        # session with a +client_id+ and you implicitly only allow lookups for
        # instances owned by that client, through storing the value with the
        # model in a field of the same name. The previous example changes only
        # a little:
        #
        #     def list( context )
        #       finder = SomeModel.list_finder( context )
        #       finder = finder.where( :client_id => context.session.client_id )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.body = results
        #     end
        #
        # Any of the ActiveRecord::QueryMethods can be called on the returned
        # value. See:
        #
        # http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html
        #
        # +context+:: ApiTools::ServiceContext instance.
        #
        def list_finder( context )
          finder = self
          finder = finder.offset( context.request.list_offset ).limit( context.request.list_limit )
          finder = finder.order( { context.request.list_sort_key => context.request.list_sort_direction.to_sym } )

          search_map = class_variable_get( '@@nz_co_loyalty_list_search_map' )

          unless search_map.nil?
            search_map.each do | attr, proc |
              value = context.request.list_search_data[ attr ]
              next if value.nil?

              if ( proc.nil? )
                args_for_where = [ { attr => value } ]
              else
                args_for_where = proc.call( attr, value )
              end

              finder = finder.where( *args_for_where )
            end
          end

          filter_map = class_variable_get( '@@nz_co_loyalty_list_filter_map' )

          unless filter_map.nil?
            filter_map.each do | attr, proc |
              value = context.request.list_filter_data[ attr ]
              next if value.nil?

              if ( proc.nil? )
                args_for_where_not = [ { attr => value } ]
              else
                args_for_where_not = proc.call( attr, value )
              end

              finder = finder.where.not( *args_for_where_not )
            end
          end
        end

        # Specify a search mapping for use by #list_finder to automatically
        # restrict list results.
        #
        # Simple example which just looks for verbatim field matches on
        # fields +name+ and +colour+:
        #
        #     class SomeModel < ActiveRecord::Base
        #       list_search_map {
        #         :name => nil,
        #         :colour => nil
        #       }
        #     end
        #
        # More complex example where +colour+ is matched verbatim, but +name+
        # is matched case-insensitive:
        #
        #     class SomeModel < ActiveRecord::Base
        #       list_search_map {
        #         :name => Proc.new { | attr, value |
        #           [ "name ILIKE ?", value ]
        #         },
        #         :colour => nil
        #       }
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
        #       list_search_map {
        #         :name   => CI_MATCH,
        #         :colour => CI_MATCH
        #       }
        #     end
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
        def list_search_map( map )
          class_variable_set( '@@nz_co_loyalty_list_search_map', map )
        end

        # As #list_search_map, but used in +where.not+ queries.
        #
        # +map+:: As #list_search_map.
        #
        def list_filter_map( map )
          class_variable_set( '@@nz_co_loyalty_list_filter_map', map )
        end
      end
    end
  end
end
