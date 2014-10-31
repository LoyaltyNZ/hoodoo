########################################################################
# File::    service_context.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Container for information about the context of a call to
#           a service, including session, request and response.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
########################################################################

module ApiTools

  # A collection of objects which describe the context in which a service is
  # being called. The service reads session and request information and returns
  # results of its processing via the associated response object.
  #
  class ServiceContext

    # The ApiTools::ServiceSession instance describing the authorised call
    # context.
    #
    attr_reader :session

    # The ApiTools::ServiceRequest instance giving details about the inbound
    # request. Relevant information will depend upon the endpoint service
    # implementation action being addressed.
    #
    attr_reader :request

    # The ApiTools::ServiceResponse instance that a service implementation
    # updates with results of its processing.
    #
    attr_reader :response

    # Create a new instance.
    #
    # +session+:: See #session.
    # +request+:: See #request.
    # +response+:: See #response.
    # +middleware+:: ApiTools::ServiceMiddleware instance creating this item.
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
    # ApiTools::ServiceMiddleware::ServiceEndpoint.
    #
    # You can request an endpoint for any resource name, whether or not an
    # implementation actually exists for it. Until you try and talk to the
    # interface through the endpoint instance, you won't know if it is there.
    # Examine the returned value's ApiTools::ServiceResponse#http_status_code
    # to see if you got a 404.
    #
    # +resource+:: Resource name for the endpoint, e.g. +:Purchase+. String
    #              or symbol.
    #
    # +version+::  Optional required implemented version for the endpoint, as
    #              an Integer - defaults to 1.
    #
    def resource( resource_name, version = 1 )
      @endpoints[ "#{ resource_name }/#{ version }" ] ||= ApiTools::ServiceMiddleware::ServiceEndpoint.new(
        @middleware,
        resource_name,
        version
      )
    end
  end
end
