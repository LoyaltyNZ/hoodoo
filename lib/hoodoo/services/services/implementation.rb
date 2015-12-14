########################################################################
# File::    implementation.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Service authors create subclasses of
#           Hoodoo::Services::Service, which lists the one or more
#           subclasses of Hoodoo::Services::Interface the service author
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

module Hoodoo; module Services

  # Service authors subclass this to produce the body of their service
  # interface implementation. It defines a series of methods that must be
  # implemented in order to service requests.
  #
  # A Hoodoo::Services::Implementation subclass is selected by the platform
  # middleware because a Hoodoo::Services::Interface subclass tells it about
  # the implementation class through the Hoodoo::Services::Interface::interface
  # DSL; the interface class is referenced from an
  # Hoodoo::Services::Service subclass through the
  # Hoodoo::Services::Service::comprised_of DSL; and the application class
  # is run by Rack by being passed to a call to +run+ in +config.ru+.
  #
  class Implementation

    # Implement a "list" action (paginated, sorted list of resources).
    #
    # +context+:: Hoodoo::Services::Context instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def list( context )
      raise "Hoodoo::Services::Implementation subclasses must implement 'list'"
    end

    # Implement a "show" action (represent one existing resource instance).
    #
    # +context+:: Hoodoo::Services::Context instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def show( context )
      raise "Hoodoo::Services::Implementation subclasses must implement 'show'"
    end

    # Implement a "create" action (store one new resource instance).
    #
    # +context+:: Hoodoo::Services::Context instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def create( context )
      raise "Hoodoo::Services::Implementation subclasses must implement 'create'"
    end

    # Implement a "update" action (modify one existing resource instance).
    #
    # +context+:: Hoodoo::Services::Context instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def update( context )
      raise "Hoodoo::Services::Implementation subclasses must implement 'update'"
    end

    # Implement a "delete" action (delete one existing resource instance).
    #
    # +context+:: Hoodoo::Services::Context instance describing authorised
    #             session information, inbound request information and holding
    #             the response object that the service updates with the results
    #             of its processing of this action.
    #
    def delete( context )
      raise "Hoodoo::Services::Implementation subclasses must implement 'delete'"
    end

    # Optional verification to allow or deny authorisation for a particular
    # action on a call-by-call basis.
    #
    # The middleware calls this method if a session
    # (Hoodoo::Services::Session) has associated permissions
    # (Hoodoo::Services::Permissions) which say that the resource's
    # implementation should be asked via constant
    # (Hoodoo::Services::Permissions::ASK).
    #
    # +context+:: Hoodoo::Services::Context instance as for action methods
    #             such as #show, #list and so forth.
    #
    # +action+::  The action that the caller is trying to perform, as a
    #             Symbol from the list in
    #             Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
    #
    # Your implementation *MUST* return either
    # Hoodoo::Services::Permissions::ALLOW, to allow the action, or
    # Hoodoo::Services::Permissions::DENY, to block the action.
    #
    # * If a session's permissions indicate that a resource endpoint should
    #   be asked, but that interface does not define its own #verify method,
    #   then the default implementation herein will _deny_ the request.
    #
    # * If a buggy verification method returns an unexpected value, the
    #   middleware will ignore it and again _deny_ the request.
    #
    # Whether or not any of your implementations ever need to write a custom
    # verification method will depend entirely upon your API, whether or not
    # it has a meaningful definition of per-request assessment to allow or
    # deny access and whether or not any sessions can exist with an 'ask'
    # permission inside in the first place. If using the Hoodoo authorisation
    # and authentication mechanism, this would come down to whether or not
    # any Hoodoo::Data::Resources::Caller instances existed with the
    # relevant permission value defined somewhere inside.
    #
    def verify( context, action )
      return Hoodoo::Services::Permissions::DENY
    end

  end

end; end
