########################################################################
# File::    client.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Let people talk to Hoodoo resource endpoints from outside
#           as easily as resource endpoints can talk to one another.
# ----------------------------------------------------------------------
#           25-Feb-2015 (ADH): Created.
########################################################################

module Hoodoo

  # Hoodoo::Client makes it very easy to call resource endpoints over API,
  # complete with automatic session management if required.
  #
  # First, a Client instance is created. This is then asked for resource
  # endpoints - in essence, treated as an enpoint factory. Calls are then
  # made through those endpoints.
  #
  # If we had resources with only +public_actions+ declared on "test.com",
  # so no sessions were needed, then the Client instantation is very easy:
  #
  #     client = Hoodoo::Client.new( base_uri: 'http://test.com/' )
  #
  # Next, let's ask it for an endpoint of resource "Member" implementing
  # version 2 of its interface.
  #
  #     members = client.resource( :Member, 1 )
  #
  # Now we can perform operations on the endpoints according to the methods
  # in the base class - see these for details:
  #
  # * Hoodoo::Client::Endpoint#list
  # * Hoodoo::Client::Endpoint#show
  # * Hoodoo::Client::Endpoint#create
  # * Hoodoo::Client::Endpoint#update
  # * Hoodoo::Client::Endpoint#delete
  #
  # The above reference describes the basic approach for each call, with
  # common parameters such as the query hash or body hash data described
  # in Hoodoo::Client::Endpoint#new.
  #
  # As an example, we could list records 50-79 inclusive of "Member"
  # sorted by +created_at+ ascending and embedding an "account" for each:
  #
  #     results = members.list(
  #       :offset    => 50,
  #       :limit     => 25,
  #       :sort      => :created_at,
  #       :direction => :asc,
  #       :embeds    => 'account'
  #     )
  #
  class Client

    public

      def initialize( base_uri:              nil,
                      drb_uri:               nil,
                      drb_port:              nil,

                      locale:                nil,

                      session_id:            nil,
                      auto_session:          :true,
                      auto_session_resource: 'Session',
                      auto_session_version:  1,
                      caller_id:             nil,
                      caller_secret:         nil )

        @endpoints = {}
        @base_uri  = base_uri
        @drb_uri   = drb_uri
        @drb_port  = drb_port

        @locale    = locale

        if @base_uri != nil
          @discoverer = Hoodoo::Services::Discovery::ByConvention.new(
            :base_uri => @base_uri
          )
        elsif @drb_uri != nil || @drb_port != nil
          @discoverer = Hoodoo::Services::Discovery::ByDRb.new(
            :drb_uri  => @drb_uri,
            :drb_port => @drb_port
          )
        end

        if @discoverer.nil?
          raise 'Hoodoo::Client: Please pass one of the "base_uri", "drb_uri" or "drb_port" parameters.'
        end

        # If doing automatic sessions, acquire a session creation endpoint

        @session_id    = session_id
        @caller_id     = caller_id
        @caller_secret = caller_secret

        if auto_session
          @auto_session_endpoint = Hoodoo::Client::Endpoint.endpoint_for(
            auto_session_resource,
            auto_session_version,
            { :discoverer => @discoverer }
          )
        end
      end

      def resource( resource, version = 1 )
        resource = resource.to_sym
        version  = version.to_i

        @endpoints[ resource ] ||= {}

        endpoint = @endpoints[ resource ][ version ]
        return endpoint unless endpoint.nil?

        endpoint = Hoodoo::Client::Endpoint.endpoint_for(
          resource,
          version,
          {
            :discoverer => @discoverer,
            :session_id => @session_id,
            :locale     => @locale
          }
        )

        unless @auto_session_endpoint.nil?
          remote_discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
            :resource         => resource,
            :version          => version,
            :wrapped_endpoint => endpoint
          )

          endpoint = Hoodoo::Client::Endpoint::AutoSession.new(
            resource,
            version,
            :caller_id => @caller_id,
            :caller_secret => @caller_secret,
            :session_endpoint => @auto_session_endpoint,
            :discovery_result => remote_discovery_result
          )
        end

        @endpoints[ resource ][ version ] = endpoint
        return endpoint
      end

  end
end
