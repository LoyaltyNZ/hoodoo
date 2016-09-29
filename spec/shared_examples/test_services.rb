#
# This script defines the following Services.
# Clients can call into any of them to invoke the different calling semantics
# between them.
#
#
# ┌──────────────────────────────────────────────┐ ┌──────────────────────────┐
# │                                              │ │                          │
# │               RSpecNumberService             │ │ RSpecRemoteNumberService │
# │                                              │ │                          │
# │                                              │ │                          │
# │ ┌──────────────┐           ┌────────────────┐│ │  ┌───────────────────┐   │
# │ │              │  inter    │                ││ │  │                   │   │
# │ │ RSpecNumber  │◀resource ─│RSpecEvenNumber ││ │  │  RSpecOddNumber   │   │
# │ │              │  local    │                ││ │  │                   │   │
# │ └──────────────┘           └────────────────┘│ │  └───────────────────┘   │
# │         ▲                                    │ │            │             │
# │         │                            inter   │ │            │             │
# │         └───────────────────────────resource ┼─┼────────────┘             │
# │                                      remote  │ │                          │
# └──────────────────────────────────────────────┘ └──────────────────────────┘
# ┌──────────────────────────┐
# │                          │
# │  RSpecNonHoodooService   │
# │                          │
# └──────────────────────────┘

################################################################################
#
# Create a 'RSpecNumber' Resource with the following properties:
#
# - manages 'Number' resources ie: { 'number': 3 }, for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
# - pagination
# - will generate an error when asked to retrieve any 'Number' resource with a
#   number value >= 500 && filter_data['force_error'] is set (to anything)
#
class RSpecNumberImplementation < Hoodoo::Services::Implementation

  public

  # Number resources are all in this range
  NUMBER_RANGE = 0..999

  # Number resources that generate errors are all in this range
  ERROR_RANGE  = 500..999

  def list( context )
    request  = context.request

    resources = []
    implode = false
    0.upto( request.list.limit - 1 ) do |i|
      num = request.list.offset + i
      implode = implode || ERROR_RANGE.include?( num )
      if NUMBER_RANGE.include?( num )
        resources << { 'number' => num }
      else
        break
      end
    end

    context.response.set_resources( resources, resources.count )
    if implode && request.list.filter_data[ 'force_error' ]
      context.response.add_error( 'platform.malformed' )
    end
  end

end

#
# Interface for our implementation
#
class RSpecNumberInterface < Hoodoo::Services::Interface
  interface :RSpecNumber do
    endpoint       :numbers, RSpecNumberImplementation
    public_actions :list
  end
end


################################################################################
#
# Create a 'RSpecEvenNumber' Resource with the following properties:
#
# - Calls RSpecNumber via the 'inter_resource_local' calling mechanism
# - Only returns 'even' numbers, 0, 2, 4...
# - provides a public 'list' endpoint (no session needed)
#
# See RSpecNumberImplementation for error handling etc
#
class RSpecEvenNumberImplementation < Hoodoo::Services::Implementation

  public

  def list( context )
    request   = context.request
    endpoint  = context.resource( :RSpecNumber, 1 )
    resources = []
    limit     = request.list.limit  ? request.list.limit  : 50
    offset    = request.list.offset ? request.list.offset : 0

    # We always iterate through every Number resource - yeah its dumb
    endpoint.list( { :filter => request.list.filter_data } ).enumerate_all do | number_res |

      if number_res.platform_errors.has_errors?
        context.response.add_errors( number_res.platform_errors )
        break
      end

      number = number_res['number']

      # Number in the correct range & is 'even'
      resources << number_res if number >= ( offset * 2 ) && number.even?
      break if resources.size >= limit

    end

    context.response.set_resources( resources, resources.count )
  end

end

#
# Interface for our implementation
#
class RSpecEvenNumberInterface < Hoodoo::Services::Interface
  interface :RSpecEvenNumber do
    endpoint       :even_numbers, RSpecEvenNumberImplementation
    public_actions :list
  end
end

################################################################################
#
# Define our service, that implements both resources
#
class RSpecNumberService < Hoodoo::Services::Service
  comprised_of RSpecNumberInterface,
               RSpecEvenNumberInterface
end


################################################################################
#
# Create a 'RSpecOddNumber' Resource with the following properties:
#
# - Calls RSpecNumber via the 'inter_resource_remote' calling mechanism
# - Only returns 'odd' numbers, 1, 3, 5 ...
# - provides a public 'list' endpoint (no session needed)
#
# See RSpecNumberImplementation for error handling etc
#
class RSpecOddNumberImplementation < Hoodoo::Services::Implementation

  public

  def list( context )
    request   = context.request
    endpoint  = context.resource( :RSpecNumber, 1 )
    resources = []
    limit     = request.list.limit  ? request.list.limit  : 50
    offset    = request.list.offset ? request.list.offset : 0

    # We always iterate through every Number resource - yeah its dumb
    endpoint.list( { :filter => request.list.filter_data } ).enumerate_all do | number_res |

      if number_res.platform_errors.has_errors?
        context.response.add_errors( number_res.platform_errors )
        break
      end

      number = number_res['number']

      # Number in the correct range & is 'odd'
      resources << number_res if number >= ( offset * 2 ) && number.odd?
      break if resources.size >= limit

    end

    context.response.set_resources( resources, resources.count )
  end

end

#
# Interface for our implementation
#
class RSpecOddNumberInterface < Hoodoo::Services::Interface
  interface :RSpecOddNumber do
    endpoint       :odd_numbers, RSpecOddNumberImplementation
    public_actions :list
  end
end

################################################################################
#
# Define our service, that implements both resources
#
class RSpecRemoteNumberService < Hoodoo::Services::Service
  comprised_of RSpecOddNumberInterface
end

################################################################################
#
# Define a non Hoodoo style app that will:
#
# - respond to a 'list' request, with a response that does NOT conform to Hoodoo
#   response standards
#
class RSpecNonHoodooService
  def call(env)
    return [200, {'Content-Type' => 'application/json'}, ['{ "message": "Hello" }'] ]
  end
end
