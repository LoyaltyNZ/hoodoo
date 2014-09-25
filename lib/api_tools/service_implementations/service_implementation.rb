module ApiTools

  # Service authors subclass this to produce the body of their service
  # interface implementation. It defines a series of methods that must be
  # implemented in order to service requests.
  #
  # An ApiTools::ServiceImplementation subclass is selected by the platform
  # middleware because an ApiTools::ServiceInterface subclass tells it about
  # the implementation class through the ApiTools::ServiceInterface::interface
  # DSL; the interface class is referenced from an
  # ApiTools::ServiceApplication subclass through the
  # ApiTools::ServiceApplication::comprised_of DSL; and the application class
  # is run by Rack by being passed to a call to +run+ in +config.ru+.
  #
  class ServiceImplementation

    # Implement a "list" action (paginated, sorted list of resources).
    #
    # +request+::  ApiTools::ServiceRequest instance for the inbound request.
    # +response+:: ApiTools::ServiceResponse instance which the service updates
    #              with the results of its processing of this action.
    #
    def list( request, response )
      raise "ApiTools::ServiceImplementation subclasses must implement 'list'"
    end

    # Implement a "show" action (represent one existing resource instance).
    #
    # +request+::  ApiTools::ServiceRequest instance for the inbound request.
    # +response+:: ApiTools::ServiceResponse instance which the service updates
    #              with the results of its processing of this action.
    #
    def show( request, response )
      raise "ApiTools::ServiceImplementation subclasses must implement 'show'"
    end

    # Implement a "create" action (store one new resource instance).
    #
    # +request+::  ApiTools::ServiceRequest instance for the inbound request.
    # +response+:: ApiTools::ServiceResponse instance which the service updates
    #              with the results of its processing of this action.
    #
    def create( request, response )
      raise "ApiTools::ServiceImplementation subclasses must implement 'create'"
    end

    # Implement a "update" action (modify one existing resource instance).
    #
    # +request+::  ApiTools::ServiceRequest instance for the inbound request.
    # +response+:: ApiTools::ServiceResponse instance which the service updates
    #              with the results of its processing of this action.
    #
    def update( request, response )
      raise "ApiTools::ServiceImplementation subclasses must implement 'update'"
    end

    # Implement a "delete" action (delete one existing resource instance).
    #
    # +request+::  ApiTools::ServiceRequest instance for the inbound request.
    # +response+:: ApiTools::ServiceResponse instance which the service updates
    #              with the results of its processing of this action.
    #
    def delete( request, response )
      raise "ApiTools::ServiceImplementation subclasses must implement 'delete'"
    end
  end
end
