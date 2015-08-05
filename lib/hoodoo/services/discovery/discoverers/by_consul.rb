########################################################################
# File::    by_consul.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Discover resource endpoint locations via a registry held in
#           Consul. For AMQP-based endpoints.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Discover resource endpoint locations via a registry held in
      # Consul. For AMQP-based endpoints.
      #
      class ByConsul < Hoodoo::Services::Discovery

        protected

          # Announce the location of an instance to Consul.
          #
          # TODO: This is currently a no-op that runs through and
          # returns the result of #discover_remote.
          #
          # Call via Hoodoo::Services::Discovery::Base#announce.
          #
          # +resource+:: Passed to #discover_remote.
          # +version+::  Passed to #discover_remote.
          # +options+::  Ignored. TODO: Queue name, equivalent path.
          #
          def announce_remote( resource, version, options = {} )

            # TODO: Announce to queue discovery via Alchemy or change
            #       entire class to "ByConsul" and talk to it directly.
            #
            # @alchemy.<something>

            return discover_remote( resource, version ) # TODO: Replace
          end

          # Discover the location of an instance using Consul.
          #
          # TODO: This currently doesn't use Consul at all! It has a
          # hard-coded mapping.
          #
          # Returns a Hoodoo::Services::Discovery::ForAMQP instance if
          # the endpoint is found, else +nil+.
          #
          # Call via Hoodoo::Services::Discovery::Base#announce.
          #
          # +resource+:: Passed to #discover_remote.
          # +version+::  Passed to #discover_remote.
          #
          def discover_remote( resource, version )

            # TODO: Replace with queue discovery over Alchemy endpoint
            #       or change entire class to "ByConsul" and talk to it
            #       directly.
            #

            v    = "/v#{ version }/"
            data = {

              :Caller       => { :queue => 'service.authentication', :path => v + 'callers'         },
              :Session      => { :queue => 'service.authentication', :path => v + 'sessions'        },

              :Log          => { :queue => 'service.logging',        :path => v + 'logs'            },
              :Errors       => { :queue => 'service.logging',        :path => v + 'errors'          },
              :Statistic    => { :queue => 'service.logging',        :path => v + 'statistics'      },

              :Tag          => { :queue => 'service.tag',            :path => v + 'tags'            },
              :MassTagEvent => { :queue => 'service.tag',            :path => v + 'mass_tag_events' },
              :Metadata     => { :queue => 'service.tag',            :path => v + 'metadata'        },

              :Balance      => { :queue => 'service.financial',      :path => v + 'balances'        },
              :Currency     => { :queue => 'service.financial',      :path => v + 'currencies'      },
              :Voucher      => { :queue => 'service.financial',      :path => v + 'vouchers'        },
              :Calculation  => { :queue => 'service.financial',      :path => v + 'calculations'    },
              :Accumulation => { :queue => 'service.financial',      :path => v + 'accumulations'   },
              :Credit       => { :queue => 'service.financial',      :path => v + 'credits'         },
              :Debit        => { :queue => 'service.financial',      :path => v + 'debits'          },
              :Ledger       => { :queue => 'service.financial',      :path => v + 'ledgers'         },

              :Programme    => { :queue => 'service.programme',      :path => v + 'programmes'      },
              :Participant  => { :queue => 'service.programme',      :path => v + 'participants'    },
              :Outlet       => { :queue => 'service.programme',      :path => v + 'outlets'         },
              :Involvement  => { :queue => 'service.programme',      :path => v + 'involvements'    },

              :Account      => { :queue => 'service.member',         :path => v + 'accounts'        },
              :Member       => { :queue => 'service.member',         :path => v + 'members'         },
              :Token        => { :queue => 'service.member',         :path => v + 'tokens'          },
              :Membership   => { :queue => 'service.member',         :path => v + 'memberships'     },

              :Product      => { :queue => 'service.product',        :path => v + 'products'        },

              :Estimation   => { :queue => 'service.purchase',       :path => v + 'estimations'     },
              :Purchase     => { :queue => 'service.purchase',       :path => v + 'purchases'       },
              :Refund       => { :queue => 'service.purchase',       :path => v + 'refunds'         },

              :Health       => { :queue => 'service.utility',        :path => v + 'health'          },
              :Version      => { :queue => 'service.utility',        :path => v + 'version'         },

            }[ resource.to_sym ]

            if data.nil?
              return nil
            else
              return Hoodoo::Services::Discovery::ForAMQP.new(
                resource:        resource,
                version:         version,
                queue_name:      data[ :queue ],
                equivalent_path: data[ :path  ]
              )
            end

          end

      end
    end
  end
end
