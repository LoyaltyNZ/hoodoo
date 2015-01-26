########################################################################
# File::    service_implementation.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Service authors create subclasses of
#           Hoodoo::ServiceApplication, which lists the one or more
#           subclasses of Hoodoo::ServiceInterface the service author
#           writes; each of those declares an interface which refers,
#           for each interface endpoint, to a subclass of the class
#           described here. Service authors create the body of their
#           service implementation within the subclass.
#
#           This file, then, does very little beyond describing the
#           method framework that service authors use.
# ----------------------------------------------------------------------
#           24-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo

  # Service authors subclass this to produce the body of their service
  # interface implementation. It defines a series of methods that must be
  # implemented in order to service requests.
  #
  # An Hoodoo::ServiceImplementation subclass is selected by the platform
  # middleware because an Hoodoo::ServiceInterface subclass tells it about
  # the implementation class through the Hoodoo::ServiceInterface::interface
  # DSL; the interface class is referenced from an
  # Hoodoo::ServiceApplication subclass through the
  # Hoodoo::ServiceApplication::comprised_of DSL; and the application class
  # is run by Rack by being passed to a call to +run+ in +config.ru+.
  #
  class ServiceImplementation

    # Implement a "list" action (paginated, sorted list of resources).
    #
    # +context+:: Hoodoo::ServiceContext instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def list( context )
      raise "Hoodoo::ServiceImplementation subclasses must implement 'list'"
    end

    # Implement a "show" action (represent one existing resource instance).
    #
    # +context+:: Hoodoo::ServiceContext instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def show( context )
      raise "Hoodoo::ServiceImplementation subclasses must implement 'show'"
    end

    # Implement a "create" action (store one new resource instance).
    #
    # +context+:: Hoodoo::ServiceContext instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def create( context )
      raise "Hoodoo::ServiceImplementation subclasses must implement 'create'"
    end

    # Implement a "update" action (modify one existing resource instance).
    #
    # +context+:: Hoodoo::ServiceContext instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def update( context )
      raise "Hoodoo::ServiceImplementation subclasses must implement 'update'"
    end

    # Implement a "delete" action (delete one existing resource instance).
    #
    # +context+:: Hoodoo::ServiceContext instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def delete( context )
      raise "Hoodoo::ServiceImplementation subclasses must implement 'delete'"
    end
  end
end
