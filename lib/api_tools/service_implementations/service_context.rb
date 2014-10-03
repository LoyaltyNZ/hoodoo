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
    #
    def initialize( session, request, response )
      @session = session
      @request = request
      @response = response
    end
  end
end
