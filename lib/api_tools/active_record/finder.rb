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

      def self.polymorphic_find( finder, ident )
        id_fields  = [ :id ]
        id_fields += @@_api_tools_show_id_fields unless @@_api_tools_show_id_fields.nil?

        id_fields.each do | field |
          checker = finder.where( field => ident )
          return checker.first unless checker.count == 0
        end

        return nil
      end

      def self.polymorphic_id_fields( array )
        @@_api_tools_show_id_fields = array
      end

      def self.list_finder( context )
        finder = self
        finder = finder.offset( context.request.list_offset ).limit( context.request.list_limit )
        finder = finder.order( { context.request.list_sort_key => context.request.list_sort_direction.to_sym } )

        unless @@_api_tools_list_search_data.nil?
          @@_api_tools_list_search_data.each do | attr, args_for_where |
            value = context.request.list_search_data[ attr ]
            next if value.nil?

            args_for_where ||= [ { attr => value } ]
            finder = finder.where( *args_for_where )
          end
        end

        unless @@_api_tools_list_filter_data.nil?
          @@_api_tools_list_filter_data.each do | attr, args_for_where_not |
            value = context.request.list_filter_data[ attr ]
            next if value.nil?

            args_for_where ||= [ { attr => value } ]
            finder = finder.where.not( *args_for_where_not )
          end
        end
      end

      def self.list_search_map( data )
        @@_api_tools_list_search_data = data
      end

      def self.list_filter_map( data )
        @@_api_tools_list_filter_data = data
      end
    end
  end
end
