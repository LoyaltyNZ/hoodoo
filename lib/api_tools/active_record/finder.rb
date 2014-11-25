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

      def self.included( model )
        model.extend( ClassMethods )
      end

      module ClassMethods

        def polymorphic_find( finder, ident )
          extra_fields = class_variable_get( '@@_api_tools_show_id_fields' ) || []
          id_fields    = [ :id ] + extra_fields

          id_fields.each do | field |
            checker = finder.where( field => ident )
            return checker.first unless checker.count == 0
          end

          return nil
        end

        def polymorphic_id_fields( *args )
          class_variable_set( '@@_api_tools_show_id_fields', args )
        end

        def list_finder( context )
          finder = self
          finder = finder.offset( context.request.list_offset ).limit( context.request.list_limit )
          finder = finder.order( { context.request.list_sort_key => context.request.list_sort_direction.to_sym } )

          search_map = class_variable_get( '@@_api_tools_list_search_map' )

          unless search_map.nil?
            search_map.each do | attr, args_for_where |
              value = context.request.list_search_data[ attr ]
              next if value.nil?

              args_for_where ||= [ { attr => value } ]
              finder = finder.where( *args_for_where )
            end
          end

          filter_map = class_variable_get( '@@_api_tools_list_filter_map' )

          unless filter_map.nil?
            filter_map.each do | attr, args_for_where_not |
              value = context.request.list_filter_data[ attr ]
              next if value.nil?

              args_for_where ||= [ { attr => value } ]
              finder = finder.where.not( *args_for_where_not )
            end
          end
        end

        def list_search_map( map )
          class_variable_set( '@@_api_tools_list_search_map', map )
        end

        def list_filter_map( map )
          class_variable_set( '@@_api_tools_list_filter_map', map )
        end
      end
    end
  end
end
