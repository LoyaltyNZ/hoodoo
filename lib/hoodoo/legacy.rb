########################################################################
# File::    legacy.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Map from old to new. This will be deleted in due course.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Created.
########################################################################

ApiTools                                     = Hoodoo

ApiTools::ServiceMiddleware                  = Hoodoo::Services::Middleware
ApiTools::ServiceMiddleware::ServiceEndpoint = Hoodoo::Services::Middleware::Endpoint

ApiTools::ServiceApplication                 = Hoodoo::Services::Service
ApiTools::ServiceContext                     = Hoodoo::Services::Context
ApiTools::ServiceImplementation              = Hoodoo::Services::Implementation
ApiTools::ServiceInterface                   = Hoodoo::Services::Interface
ApiTools::ServiceRequest                     = Hoodoo::Services::Request
ApiTools::ServiceResponse                    = Hoodoo::Services::Response
ApiTools::ServiceSession                     = Hoodoo::Services::Session
