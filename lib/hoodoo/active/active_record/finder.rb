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
    # based on inbound data. See:
    #
    # * http://guides.rubyonrails.org/active_record_basics.html
    #
    module Finder
      
      class Slice

        attr_reader :data, :count, :rendered_data

        def initialize(data, count)
          @data = data
          @count = count
          @rendered_data = @data
        end

        def render_with(&block)
          @rendered_data = @data.map(&block)
          @rendered_data
        end
 
      end
      # Instantiates this module when it is included:
      #
      # Example:
      #
      #     class SomeModel < ActiveRecord::Base
      #       include Hoodoo::ActiveRecord::Finder
      #       # ...
      #     end
      #
      def self.included( model )
        instantiate( model ) unless model == Hoodoo::ActiveRecord::Base
      end

      # When instantiated in an ActiveRecord::Base subclass, all of the
      # Hoodoo::ActiveRecord::Finder::ClassMethods methods are defined as
      # class methods on the including class.
      #
      def self.instantiate( model )
        model.extend( ClassMethods )
      end

      # Collection of class methods that get defined on an including class via
      # Hoodoo::ActiveRecord::Finder::included.
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
        #       include Hoodoo::ActiveRecord::Finder
        #       polymorphic_id_fields # ...<list-of-other-fields>
        #     end
        #
        #     # ...elsewhere...
        #
        #     def show( context )
        #       found = SomeModel.polymorphic_find( SomeModel, context.request.ident )
        #
        #       # ...map 'found' to whatever resource you're representing,
        #       # e.g. via a Hoodoo::Presenters::Base subclass with resource
        #       # schema and the subclass's Hoodoo::Presenters::Base::render
        #       # call, then...
        #
        #       context.response.set_resource( resource_representation_of_found )
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

          extra_fields = class_variable_defined?( :@@nz_co_loyalty_show_id_fields ) ? class_variable_get( :@@nz_co_loyalty_show_id_fields ) : nil
          id_fields    = [ :id ] + ( extra_fields || [] )

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
            checker = finder.where( [ "#{ field } = ?", ident ] )
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
        #       include Hoodoo::ActiveRecord::Finder
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
        # Hoodoo::Services::Context. It takes into account the context's
        # Hoodoo::Services::Request and the list offset, list limit, list sort
        # key and list sort direction automatically. In addition, it can do
        # simple search and filter operations if search and filter mappings
        # are set up via #list_search_map and #list_filter_map.
        #
        # For exampe, in a simple case where a model can be listed without any
        # unusual constraints, we might do this:
        #
        #     class SomeModel < ActiveRecord::Base
        #       include Hoodoo::ActiveRecord::Finder
        #
        #       list_search_map # ...<field-to-search-info mapping>
        #       # ...and/or...
        #       list_filter_map # ...<field-to-search-info mapping>
        #     end
        #
        #     # ...elsewhere...
        #
        #     def list( context )
        #       finder = SomeModel.list_finder( context.request.list )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.set_resources( results )
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
        #       finder = SomeModel.list_finder( context.request.list )
        #       finder = finder.where( :client_id => context.session.client_id )
        #       results = finder.all.map do | item |
        #         # ...map database objects to response objects...
        #       end
        #       context.response.set_resources( results )
        #     end
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
        def list_finder( list_parameters )
          finder = self.apply_search_and_filter_maps(list_parameters.search_data, list_parameters.filter_data)
          finder = finder.offset( list_parameters.offset ).limit( list_parameters.limit )
          finder = finder.order( { list_parameters.sort_key => list_parameters.sort_direction.to_sym } )
          return finder
        end

        def apply_search_and_filter_maps(search_data, filter_data)
          scope = self.all
          search_map = class_variable_defined?( :@@nz_co_loyalty_list_search_map ) ? class_variable_get( :@@nz_co_loyalty_list_search_map ) : nil
          unless search_map.nil?
            scope = scope.apply_search_map(search_map, search_data)
          end

          filter_map = class_variable_defined?( :@@nz_co_loyalty_list_filter_map ) ? class_variable_get( :@@nz_co_loyalty_list_filter_map ) : nil
          unless filter_map.nil?
            scope = scope.apply_filter_map(filter_map, filter_data)
          end
          scope
        end

        def dry_proc(data, attr, proc)
          value = data[ attr.to_s ]
          return nil if value.nil?

          if ( proc.nil? )
            [ { attr => value } ]
          else
            proc.call( attr, value )
          end
        end

        def apply_filter_map(filter_map, filter_data)
          scope = self.all
          filter_map.each do | attr, proc |
            args   = dry_proc(filter_data, attr, proc )
            scope = scope.where.not( *args ) unless args.nil?
          end
          scope
        end

        def apply_search_map(search_map, search_data)
          scope = self.all
          search_map.each do | attr, proc |
            args  = dry_proc( search_data, attr, proc )
            scope = scope.where( *args ) unless args.nil?
          end
          scope
        end

        def slice(list_parameters)
          scope = self.apply_search_and_filter_maps(list_parameters.search_data, list_parameters.filter_data)
          
          count = scope.clone.count

          scope = scope.offset( list_parameters.offset ).limit( list_parameters.limit )
          scope = scope.order( { list_parameters.sort_key => list_parameters.sort_direction.to_sym } )          

          return Slice.new(scope, count)
        end


        # Specify a search mapping for use by #list_finder to automatically
        # restrict list results.
        #
        # Simple example which just looks for verbatim field matches on
        # fields +name+ and +colour+:
        #
        #     class SomeModel < ActiveRecord::Base
        #       list_search_map(
        #         :name => nil,
        #         :colour => nil
        #       )
        #     end
        #
        # More complex example where +colour+ is matched verbatim, but +name+
        # is matched case-insensitive, assuming PostgreSQL's ILIKE is there:
        #
        #     class SomeModel < ActiveRecord::Base
        #       list_search_map(
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
        #       list_search_map(
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
        def list_search_map( map )
          class_variable_set( '@@nz_co_loyalty_list_search_map', Hoodoo::Utilities.stringify( map ) )
        end

        # As #list_search_map, but used in +where.not+ queries.
        #
        # +map+:: As #list_search_map.
        #
        def list_filter_map( map )
          class_variable_set( '@@nz_co_loyalty_list_filter_map', Hoodoo::Utilities.stringify( map ) )
        end
      end
    end
  end
end
