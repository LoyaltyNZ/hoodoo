########################################################################
# File::    make.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Process service application source code, loading interfaces
#           and writing formalised representations of the APIs defined
#           therein.
#
#           Currently writes a Swagger v2.0 compliant JSON file.
#           https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md
#
# Usage::   Edit +config.yml+,
#           +bundle install+,
#           +bundle exec ruby make.rb+
# ----------------------------------------------------------------------
#           27-Nov-2014 (ADH): Created.
########################################################################

# Standard library

require 'ostruct'
require 'pathname'
require 'tmpdir'
require 'yaml'

# JSON support

require 'json'
require 'json-schema'

# Other external gems

require 'api_tools'
require 'active_support/inflector'

###############################################################################
# Configuration
###############################################################################

config = YAML.load_file( 'config.yml' )
keys   = %w{
  org_name
  org_site
  org_email

  doc_root
  doc_name
  doc_description

  host
  version
  content_types
  paths
  repositories

  output_filename
}

# Set instance variables equal to each key name above, with the config value.

keys.each do | key |
  instance_variable_set( "@#{ key }", config[ key ] )
end

###############################################################################
# Clone repositories (if present)
###############################################################################

unless @repositories.nil? || @repositories.empty?
  puts
  puts "Cloning repositories:"

  @paths = []

  @repositories.each_with_index do | repository, index  |

    puts
    puts "#{ index + 1 } of #{ @repositories.count }: #{ repository }"

    path    = Dir.mktmpdir()
    success = system( "git clone -b #{ repository } '#{ path }'")

    if success == false
      $stderr.puts "WARNING: #{ repository } failed, skipping: #{ $? }"
    else
      @paths << path
    end
  end
end

###############################################################################
# Load interfaces
###############################################################################

# Load implementation classes, in order to load interface definitions that
# refer to the implementation classes.

begin

  puts
  puts "Loading implementations:"

  @paths.each do | path |
    implementations = File.join( path, 'service', 'implementations', '*.rb' )

    Dir[ implementations ].sort.each do | implementation |
      puts "  #{ Pathname.new( implementation ).basename() }"
      load implementation
    end
  end

  puts
  puts "Loading interfaces:"

  @paths.each do | path |
    interfaces = File.join( path, 'service', 'interfaces', '*.rb' )

    Dir[ interfaces ].sort.each do | interface |
      puts "  #{ Pathname.new( interface ).basename() }"
      load interface
    end
  end

  # Collect the unique interface classes into 'interfaces'.

  interfaces = Set.new

  ObjectSpace.each_object( ApiTools::ServiceInterface.singleton_class ) do | klass |
    interfaces << klass unless klass == ApiTools::ServiceInterface
  end

  # With this, 'interfaces' becomes an Array, not a Set.

  interfaces = interfaces.sort() { | a, b | a.name <=> b.name }

  # An ad hoc class which fakes 'context.response.body' so we can hard-call the
  # Version implementation.

  version    = nil
  @version ||= '0.0.1'

  if defined?( VersionImplementation )
    puts
    puts "Reading API version:"

    begin
      class Context
        attr_accessor :response
        def initialize
          @response = OpenStruct.new
        end
      end

      context = Context.new
      VersionImplementation.new.show( context )

      data          = context.response.body
      version_major = data[ 'major' ]
      version_minor = data[ 'minor' ]
      version_patch = data[ 'patch' ]

      version = "#{ version_major }.#{ version_minor }.#{ version_patch }"

      puts "  #{ version }"
    rescue
      puts "  WARNING: Attempt failed, falling back to config.yml value of '#{ @version }'"
    end

    puts
  else
    puts
    puts "Using version #{ @version }"
    puts
  end

  version ||= @version

ensure

  # If we cloned repositories, clean up now

  unless @repositories.nil? || @repositories.empty?
    @paths.each do | path |
      FileUtils.remove_entry( path )
    end
  end

end

###############################################################################
# Define some supporting methods
###############################################################################

# Return a value suitable for use as an 'externalDocs' Swagger key's value.
#
# +resource+::   Capitalised resource name, e.g. Person, Reward, LogEntry as a
#                String or Symbol, or omit for no anchor to a resource.
#
def external_docs( resource = nil )
  url         = @doc_root.dup
  description = @doc_name.dup

  unless resource.nil?
    url         << "\##{ resource.downcase }.resource"
    description << ": #{ resource }"
  end

  {
    :description => description,
    :url         => url
  }
end

# Map ApiTools presenter DSL data to JSON schema.
#
# +resource+::   Capitalised resource name, e.g. Person, Reward, LogEntry as a
#                String or Symbol.
#
# +properties+:: Hash of properties from the inbound DSL, keyed by property
#                name as a String with an ApiTools::Presenters::Field
#                *subclass* *instance* as the value. For example, the return
#                value of hypothetical resource class call
#                ApiTools::Data::Resources::Foo.get_schema().properties() is
#                suitable here.
#
# +json+::       Top-level callers omit this parameter. Internally, it's an
#                optional hash. Its +:properties+ key is set and given a value
#                which is the hash of converted JSON schema properties.
#
# Returns a top-level Hash which is a Swagger Schema Object.
#
def to_json_schema( resource, properties, json = nil )
  if json.nil?
    json = {
      :externalDocs => external_docs( resource ),
      :properties   => {}
    }
  end

  required = []

  properties.each do | name, property |
    defn = if property.is_a?( ApiTools::Presenters::Array )
      ret   = { :type => 'array', :properties => {} }
      items = unless property.properties.nil? || property.properties.empty?
        to_json_schema( resource, property.properties, ret )
        ret.delete( :properties )
      end
      # Assumption; *something* needs to be put here, so this has to suffice.
      items = { :type => 'string' } if items.nil? || items.empty?
      ret[ :items ] = items
      ret
    elsif property.is_a?( ApiTools::Presenters::Boolean )
      {
        :type => 'boolean'
      }
    elsif property.is_a?( ApiTools::Presenters::DateTime )
      {
        :type   => 'string',
        :format => 'date-time'
      }
    elsif property.is_a?( ApiTools::Presenters::Date )
      {
        :type   => 'string',
        :format => 'date'
      }
    elsif property.is_a?( ApiTools::Presenters::Decimal )
      {
        :type        => 'string',
        :format      => 'decimal',
        :description => "Precision #{ property.precision }"
      }
    elsif property.is_a?( ApiTools::Presenters::Enum )
      list = property.from
      list = [ 'any' ] if list.nil? || list.empty?
      {
        :type => 'string',
        :enum => list
      }
    elsif property.is_a?( ApiTools::Presenters::Float )
      {
        :type   => 'number',
        :format => 'double'
      }
    elsif property.is_a?( ApiTools::Presenters::Hash )
      ret = { :type => 'object', :properties => {} }
      unless property.properties.nil? || property.properties.empty?
        # Swagger spec doesn't seem to support saying "any key with values
        # shaped like 'this'".
        if property.instance_variable_get( '@specific' ) == true
          to_json_schema( resource, property.properties, ret )
        end
      end
    elsif property.is_a?( ApiTools::Presenters::Integer )
      {
        :type   => 'integer',
        :format => 'int32'
      }
    elsif property.is_a?( ApiTools::Presenters::Object )
      ret = { :type => 'object', :properties => {} }
      unless property.properties.nil? || property.properties.empty?
        to_json_schema( resource, property.properties, ret )
      end
    elsif property.is_a?( ApiTools::Presenters::String )
      ret = { :type => 'string' }
      ret[ :maxLength ] = property.length unless property.length.nil? || property.length == 0
      ret
    elsif property.is_a?( ApiTools::Presenters::Tags )
      {
        :type   => 'string',
        :format => 'comma-separated-tag-names'
      }
    elsif property.is_a?( ApiTools::Presenters::Text )
      {
        :type => 'string'
      }
    elsif property.is_a?( ApiTools::Presenters::UUID )
      {
        :type      => 'string',
        :format    => 'uuid',
        :minLength => ApiTools::UUID.generate.length,
        :maxLength => ApiTools::UUID.generate.length
      }

    else
      warnings = true
      $stderr.puts "WARNING: Resource '#{ resource }' uses unrecognised type '#{ property.class }' in property '#{ name }'"
      nil

    end

    next if defn.nil?

    defn[ :title    ] = name
    defn[ :default  ] = property.default unless property.default.nil?

    required << name if property.required

    json[ :properties ][ name ] = defn
  end

  json[ :required ] = required unless required.empty?

  return json
end

###############################################################################
# Construct Swagger data:
# https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md
###############################################################################

warnings = false

contact = {
  :name  => @org_name,
  :url   => @org_site,
  :email => @org_email
}

license = {
  :name => "See #{ @org_name }",
  :url  => @org_site
}

termsOfService = @org_site

info = {
  :title          => @doc_name,
  :description    => @doc_description,
  :termsOfService => termsOfService,
  :contact        => contact,
  :license        => license,
  :version        => version
}

# Map of supported operations on the various interfaces.

paths                        = {}
required_reference_resources = []

interfaces.each do | interface |
  actions = interface.actions || ApiTools::ServiceMiddleware::ALLOWED_ACTIONS
  next if actions.empty?

  base = "/v#{ interface.version }/#{ interface.endpoint }"

  actions.each do | action |
    queries = ApiTools::ServiceMiddleware::ALLOWED_QUERIES_ALL.dup

    case action
      when :show
        method = :get
        path   = base + "/{ident}"
      when :list
        method   = :get
        path     = base
        queries += ApiTools::ServiceMiddleware::ALLOWED_QUERIES_LIST
      when :create
        method = :post
        path   = base + "/{ident}"
      when :update
        method = :patch
        path   = base + "/{ident}"
      when :delete
        method = :delete
        path   = base + "/{ident}"
    end

    # Parameter lists... First, do the query string stuff, which is easy.

    parameters = []
    searches   = interface.to_list.search || []
    filters    = interface.to_list.filter || []
    embeds     = interface.embeds         || []
    references = embeds

    queries.each do | query_parameter |

      next if query_parameter == 'search'     &&   searches.empty?
      next if query_parameter == 'filter'     &&    filters.empty?
      next if query_parameter == '_embed'     &&     embeds.empty?
      next if query_parameter == '_reference' && references.empty?

      type        = 'string'
      default     = nil
      enum        = nil
      description = case query_parameter.to_s
        when 'sort'
          default = interface.to_list.default_sort_key.to_s
          enum    = interface.to_list.sort.keys
          "Valid values: #{ enum.join( ', ' ) }"

        when 'direction'
          default = interface.to_list.default_sort_direction
          values  = []
          interface.to_list.sort.each do | sort, directions |
            values << "#{ sort } => #{ directions.join( ', ' ) }"
          end
          "Valid values depend on 'sort': #{ values.join( ', ' ) }"

        when 'offset'
          type    = 'integer'
          default = 0
          "List start offset"

        when 'limit'
          type    = 'integer'
          default = interface.to_list.limit
          "Number of items to return"

        when 'search'
          enum = searches
          "Include items matching URL-encoded values of 'field=search-string'; search on: #{ searches.join( ', ' ) }"

        when 'filter'
          enum = filters
          "Exclude items matching URL-encoded values of 'field=filter-string'; search on: #{ filters.join( ', ' ) }"

        when '_embed'
          enum = embeds
          "Include embedded full associated resource description(s) for: #{ embeds.join( ', ' ) }"

        when '_reference'
          enum = references
          "Include embedded UUIDs of associated resource description(s) for: #{ references.join( ', ' ) }"
      end

      parameter = {
        :name     => query_parameter,
        :in       => 'query',
        :type     => type,
        :required => false
      }

      parameter[ :format      ] = 'int32'     if     type == 'integer'
      parameter[ :description ] = description unless description.nil?
      parameter[ :default     ] = default     unless default.nil?
      parameter[ :enum        ] = enum        unless enum.nil? || enum.empty?

      parameters << parameter
    end

    # Parameters: For everything except 'list', there's {ident} in the path.

    unless action == :list
      parameters << {
        :name        => 'ident',
        :in          => 'path',
        :description => 'UUID of instance. Some endpoints support other IDs here; see full API documentation for details.',
        :required    => true,
        :type        => 'string',
        :minLength   => 1
      }
    end

    # Parameters: Body schema for 'create' and 'update'.

    if action == :create || action == :update
      dsl       = interface.send( "to_#{ action }" )
      parameter = {
        :name     => 'body',
        :in       => 'body',
        :required => true,
      }

      unless dsl.nil?
        properties = dsl.get_schema().properties
        parameter[ :schema ] = to_json_schema( interface.resource, properties )
      else
        parameter[ :schema ] = {
          :externalDocs => external_docs( interface.resource )
        }
      end

      parameters << parameter
    end

    # Put it all together

    response_schema = {
      "$ref" => "\#/definitions/#{ interface.resource }"
    }

    if action == :list
      response_schema = {
        :title => '_data',
        :type  => 'array',
        :items => response_schema
      }
    end

    ops           = {}
    ops[ method ] = {
      :tags         => [ interface.resource ],
      :summary      => "#{ action.capitalize } #{ interface.resource } instance#{ action == :list ? 's' : '' }",
      :externalDocs => external_docs( interface.resource ),
      :parameters   => parameters,
      :responses    => {
        :default    => { # All error cases
          :description => "Error conditions are described in the #{ @doc_name }"
        },
        '200' => {
          :description => "Action '#{ action }' successful",
          :schema => response_schema
        }
      }
    }

    required_reference_resources << interface.resource

    paths[ path ] ||= {}
    paths[ path ].merge!( ops )
  end
end

# Define named resource schemas used above.

resource_schemas = {}
resources        = ApiTools::Data::Resources.constants.select do | c |
  Class === ApiTools::Data::Resources.const_get( c )
end

resources.each do | resource |
  next unless required_reference_resources.include?( resource )

  klass = ApiTools::Data::Resources.const_get( resource )
  dsl   = klass.get_schema()

  resource_schemas[ resource ] = to_json_schema( resource, dsl.properties )
end

undefined_resources = required_reference_resources.uniq - resource_schemas.keys

unless undefined_resources.empty?
  $stderr.puts "WARNING: Undefined resources: '#{ undefined_resources.join( ', ' ) }'"
  warnings = true

  undefined_resources.each do | ud |
    resource_schemas[ ud ] = {
      :description => ud
    }
  end
end

security_definitions = {
  'sessionId' => {
    :type => 'apiKey',
    :in   => 'header',
    :name => 'X-Session-ID'
  }
}

root = {
  :swagger             => '2.0',
  :info                => info,
  :host                => @host,
  :schemes             => [ 'https' ],
  :consumes            => @content_types,
  :produces            => @content_types,
  :paths               => paths,
  :definitions         => resource_schemas,
  :securityDefinitions => security_definitions,
  :security            => [ 'sessionId' => [] ],
  :externalDocs        => external_docs(),
}

output = JSON.pretty_generate( root )

puts if warnings
puts "Finished."
puts "Writing file '#{ @output_filename }'..."

File.write( @output_filename, output )

###############################################################################
# Validate output
###############################################################################

puts
puts "Validating..."

schema = JSON.load( File.read( File.join( 'swagger-spec', 'schemas', 'v2.0', 'schema.json' ) ) )
again  = true
count  = 0

# SMH. Good old JSON schema, reliable as always... Even the schema server's
# screwed up.

while again == true
  begin
    count += 1
    errors = JSON::Validator.fully_validate( schema, root )
    again  = false

  rescue RuntimeError => exception
    if exception.message.include?( 'HTTP redirection loop' )
      if ( count < 4 )
        puts "HTTP redirection loop - retrying \##{ count }..."
        sleep 1
      else
        again = false
        raise "Too many attempts; giving up"
      end
    else
      raise exception
    end
  end
end

if errors.empty?
  puts "Output valid."
else
  puts "Output invalid:"
  puts errors.inspect
end

puts
