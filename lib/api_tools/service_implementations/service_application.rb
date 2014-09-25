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

  protected

    # Called by subclasses listing one or more ApiTools::ServiceInterface
    # subclasses that make up the service implementation as a whole.
    #
    def self.comprised_of( *classes )
      @component_interfaces = classes
    end

  end
end
