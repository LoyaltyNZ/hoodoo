########################################################################
# File::    context.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Container for information about the context of a call to
#           a service, including session, request and response.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services

  # A collection of objects which describe the context in which a service is
  # being called. The service reads session and request information and returns
  # results of its processing via the associated response object.
  #
  class Context

    # The Hoodoo::Services::Session instance describing the authorised call
    # context.
    #
    attr_reader :session

    # The Hoodoo::Services::Request instance giving details about the inbound
    # request. Relevant information will depend upon the endpoint service
    # implementation action being addressed.
    #
    attr_reader :request

    # The Hoodoo::Services::Response instance that a service implementation
    # updates with results of its processing.
    #
    attr_reader :response

    # Create a new instance.
    #
    # +session+:: See #session.
    # +request+:: See #request.
    # +response+:: See #response.
    # +middleware+:: Hoodoo::Services::Middleware instance creating this item.
    #
    def initialize( session, request, response, middleware )
      @session    = session
      @request    = request
      @response   = response
      @middleware = middleware
      @endpoints  = {}
    end

    # Request (and lazy-initialize) a new resource endpoint instance for
    # talking to a resource's interface. See
    # Hoodoo::Services::Middleware::Endpoint.
    #
    # You can request an endpoint for any resource name, whether or not an
    # implementation actually exists for it. Until you try and talk to the
    # interface through the endpoint instance, you won't know if it is there.
    # All endpoint methods return instances of classes that mix in
    # Hoodoo::Services::Middleware::Endpoint::AugmentedBase; these
    # mixin methods provide error handling options to detect a "not found"
    # error (equivanent to HTTP status code 404) returned when a resource
    # implementation turns out to not actually be present.
    #
    # +resource+:: Resource name for the endpoint, e.g. +:Purchase+. String
    #              or symbol.
    #
    # +version+::  Optional required implemented version for the endpoint, as
    #              an Integer - defaults to 1.
    #
    def resource( resource_name, version = 1 )
      @endpoints[ "#{ resource_name }/#{ version }" ] ||= Hoodoo::Services::Middleware::Endpoint.new(
        @middleware,
        resource_name,
        version
      )
    end
  end

end; end
