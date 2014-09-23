module ApiTools

  # ApiTools::ServiceApplication is subclassed by people writing service
  # implementations; the subclasses are the entrypoint for platform services.
  #
  # It's really just a container of one or more interface classes, which are
  # all ApiTools::ServiceInterface subclasses. The implementations of these
  # contain the body of the service's implementation and are independently
  # instantiated. The Rack middleware in ApiTools::ServiceMiddleware uses the
  # ApiTools::ServiceApplication to find out what interfaces it implements.
  # The endpoints those interfaces declare themselves to be on are used by
  # the middleware to route inbound requests to the correct interface class.
  #
  # Suppose we defined a PurchaseInterface and RefundInterface which we wanted
  # both to be available as a Shopping Service:
  #
  #     class PurchaseInterface < ApiTools::ServiceInterface
  #       interface :Purchase do
  #         endpoint :purchases
  #         # ...
  #       end
  #     end
  #
  #     class RefundInterface < ApiTools::ServiceInterface
  #       interface :Refund do
  #         endpoint :refunds
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
  # Conceptually, then, you could just have one interface per application for
  # very small services. You may prefer to logically group some interfaces in
  # a service for code structuring. Or, more realistically, efficiency may
  # dictate that certain interfaces have such heavy reliance and relationships
  # between database contents that sharing the data models between those
  # interface classes makes sense and you end up grouping them under the same
  # application without their being full decoupling. As a service author, the
  # choice is yours.
  #
  class ServiceApplication

    # Return an array of the classes that make up the interfaces for this
    # service. Each is an ApiTools::ServiceInterface subclass that was
    # registered by the subclass through a call to #comprised_of.
    #
    def self.component_interfaces
      @component_interfaces
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
