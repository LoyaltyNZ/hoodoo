########################################################################
# File::    service_registry_drb_configuration.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Configuration for the local DRb-based service registry. See
#           "service_registry_drb_server.rb" for details.
#
#           This class is almost a private implementation detail of
#           ApiTools::ServiceMiddleware. File "service_middleware.rb"
#           must be "require"'d first.
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb.
########################################################################

module ApiTools
  class ServiceMiddleware

    # URI for DRb server used during local machine development as a registry
    # of service endpoints. Whichever service starts first runs the server
    # which others connect to if subsequently started.
    #
    # Use IP address, rather than 'localhost' here, to ensure that "address
    # in use" errors are raised immediately if a second server startup attempt
    # is made:
    #
    #   https://bugs.ruby-lang.org/issues/3052
    #
    DRB_URI = 'druby://127.0.0.1:8787'

    # "disable eval() and friends":
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/drb/rdoc/DRb.html
    #
    $SAFE = 1

    # Instance to use for the DRb server.
    #
    FRONT_OBJECT = ServiceRegistryDRbServer.new

  end
end
