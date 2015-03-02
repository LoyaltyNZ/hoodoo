module Hoodoo
  module Services
    module Discovery

      # ...returns ForAMQP result...
      #
      class ByConsul < Hoodoo::Services::Discovery::Base

        protected

          def configure_with( options = {} )

            @alchemy = options[ :alchemy ]

          end

          def announce_remote( resource, version, options = {} )

            # TODO: Announce to queue discovery via Alchemy or change
            #       entire class to "ByConsul" and talk to it directly.
            #
            # @alchemy.<something>

            return discover_remote( resource, version ) # TODO: Replace
          end

          def discover_remote( resource, version, options = {} )

            # TODO: Replace with queue discovery over Alchemy endpoint
            #       or change entire class to "ByConsul" and talk to it
            #       directly.
            #

            v    = "/v#{ version }/"
            data = {

              'Health'      => { :queue => 'service.utility',   :path => v + 'health'       },
              'Version'     => { :queue => 'service.utility',   :path => v + 'version'      },

              'Log'         => { :queue => 'service.logging',   :path => v + 'logs'         },
              'Errors'      => { :queue => 'service.logging',   :path => v + 'errors'       },
              'Statistic'   => { :queue => 'service.logging',   :path => v + 'statistics'   },

              'Account'     => { :queue => 'service.member',    :path => v + 'accounts'     },
              'Member'      => { :queue => 'service.member',    :path => v + 'members'      },
              'Membership'  => { :queue => 'service.member',    :path => v + 'memberships'  },
              'Token'       => { :queue => 'service.member',    :path => v + 'tokens'       },

              'Participant' => { :queue => 'service.programme', :path => v + 'participants' },
              'Outlet'      => { :queue => 'service.programme', :path => v + 'outlets'      },
              'Involvement' => { :queue => 'service.programme', :path => v + 'involvements' },
              'Programme'   => { :queue => 'service.programme', :path => v + 'programmes'   },

              'Balance'     => { :queue => 'service.financial', :path => v + 'balances'     },
              'Currency'    => { :queue => 'service.financial', :path => v + 'currencies'   },
              'Voucher'     => { :queue => 'service.financial', :path => v + 'vouchers'     },
              'Calculation' => { :queue => 'service.financial', :path => v + 'calculations' },
              'Transaction' => { :queue => 'service.financial', :path => v + 'transactions' },

              'Purchase'    => { :queue => 'service.purchase',  :path => v + 'purchases'    },

            }[ resource.to_s ]

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
