########################################################################
# File::    service_application.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define a class that service authors subclass and use to
#           declare the component interfaces within the service via a
#           very small DSL.
#
#           This class is passed to Rack and treated like an endpoint
#           Rack application, though the service middleware in practice
#           does not pass on calls using the Rack interface; it uses the
#           custom calls exposed by ApiTools::ServiceImplementation.
#           Rack's involvement between the two is really limited to just
#           passing an instance of the service application subclass to
#           the middleware so it knows who to "talk to".
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # ApiTools::ServiceApplication is subclassed by people writing service
  # implementations; the subclasses are the entrypoint for platform services.
  #
  # It's really just a container of one or more interface classes, which are
  # all ApiTools::ServiceInterface subclasses. The Rack middleware in
  # ApiTools::ServiceMiddleware uses the ApiTools::ServiceApplication to find
  # out what interfaces it implements. Those interface classes nominate a Ruby
  # class of the author's choice in which they've written the implementation
  # for that interface. Interfaces also declare themselves to be available at
  # a particular URL endpoint (as a path fragment); this is used by the
  # middleware to route inbound requests to the correct implementation class.
  #
  # Suppose we defined a PurchaseInterface and RefundInterface which we wanted
  # both to be available as a Shopping Service:
  #
  #     class PurchaseImplementation < ApiTools::ServiceImplementation
  #       # ...
  #     end
  #
  #     class PurchaseInterface < ApiTools::ServiceInterface
  #       interface :Purchase do
  #         endpoint :purchases, PurchaseImplementation
  #         # ...
  #       end
  #     end
  #
  #     class RefundImplementation < ApiTools::ServiceImplementation
  #       # ...
  #     end
  #
  #     class RefundInterface < ApiTools::ServiceInterface
  #       interface :Refund do
  #         endpoint :refunds, RefundImplementation
  #         # ...
  #       end
  #     end
  #
  # ...then the *entire* ServiceApplication subclass for the Shopping Service
  # could be as small as this:
  #
  #     class ShoppingService < ApiTools::ServiceApplication
  #       comprised_of PurchaseInterface,
  #                    RefundInterface
  #     end
  #
  # Names of subclasses in the above examples are chosen for clarity and the
  # naming approach indicated is recommended, but it's not mandatory. Choose
  # choose whatever you feel best fits your code and style.
  #
  # Conceptually, one might just have a single interface per application for
  # very small services, but you may want to logically group more interfaces in
  # one service for code clarity/locality. More realistically, efficiency may
  # dictate that certain interfaces have such heavy reliance and relationships
  # between database contents that sharing the data models between those
  # interface classes makes sense; you would group them under the same service
  # application, sacrificing full decoupling. As a service author, the choice
  # is yours.
  #
  class ServiceApplication

    # Return an array of the classes that make up the interfaces for this
    # service. Each is an ApiTools::ServiceInterface subclass that was
    # registered by the subclass through a call to #comprised_of.
    #
    def self.component_interfaces
      @component_interfaces
    end

    # Instance method which calls through to ::component_interfaces and returns
    # its result.
    #
    def component_interfaces
      self.class.component_interfaces
    end

    # Since service implementations are not pure Rack apps but really service
    # middleware clients, they shouldn't ever have "call" invoked directly.
    # This method is not intended to be overridden and just complains if Rack
    # ends up calling here directly by accident.
    #
    # +env+:: Rack environment (ignored).
    #
    def call( env )
      raise "ApiTools::ServiceImplementation subclasses should only be called through the middleware - add 'use ApiTools::ServiceMiddleware' to (e.g.) config.ru"
    end

  protected

    # Called by subclasses listing one or more ApiTools::ServiceInterface
    # subclasses that make up the service implementation as a whole.
    #
    # Example:
    #
    #     class ShoppingService < ApiTools::ServiceApplication
    #       comprised_of PurchaseInterface,
    #                    RefundInterface
    #     end
    #
    # See this class's general ApiTools::ServiceApplication documentation for
    # more details.
    #
    def self.comprised_of( *classes )

      # http://www.ruby-doc.org/core-2.1.3/Module.html#method-i-3C
      #
      classes.each do | klass |
        unless klass < ApiTools::ServiceInterface
          raise "ApiTools::ServiceImplementation::comprised_of expects ApiTools::ServiceInterface subclasses only - got '#{ klass }'"
        end
      end

      @component_interfaces = classes
    end
  end
end
