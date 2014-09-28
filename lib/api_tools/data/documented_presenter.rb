########################################################################
# File::    documented_presenter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for predefined Type and Resource definitions
#           that inherit the ApiTools::Presenters::BasePresenter methods
#           for parsing, rendering and validation.
# ----------------------------------------------------------------------
#           26-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # Base class for predefined Type and Resource definitions
    # that inherit the ApiTools::Presenters::BasePresenter methods
    # for parsing, rendering and validation.
    #
    # See the ApiTools::Data::Types and ApiTools::Data::Resources
    # collections of subclasses for more.
    #
    class DocumentedPresenter < ApiTools::Presenters::BasePresenter

      # Define the JSON schema for validation.
      #
      # &block:: Block that makes calls to the DSL defined by
      #          ApiTools::Data::DocumentedObject.
      #
      def self.schema(&block)
        @schema = ApiTools::Data::DocumentedObject.new
        @schema.instance_eval &block
        @schema_definition = block
      end

      # Read back the block that defined the schema.
      #
      def self.schema_definition
        @schema_definition
      end

      # Return a to-JSON hash that represents this resource.
      #
      # +uuid+::       Unique ID of the resource instance that is to be
      #                represented.
      #
      # +created_at+:: Date/Time of instance creation.
      #
      # +data+::       Hash or Array (depending on resource's top-level
      #                data container type) to be represented. Data within
      #                this is compared against the schema being called to
      #                ensure that correct information is returned and
      #                unknown data is ignored.
      #
      def self.render( uuid, created_at, data )
        target = {}

        @schema.render( data, target )

        # TODO: Internationalisation key, "Kind" key

        target.merge!( {
          :id         => uuid,
          :created_at => Time.parse( created_at.to_s )
        } )
      end
    end
  end
end
