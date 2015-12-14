# Hoodoo is going open source before AlchemyAMQ, but the test suite has
# Alchemy dependencies. The Gemfile even used to require Alchemy in test
# mode directly from the private GitHub repository.
#
# That doesn't work for a public gem, so this file is a temporary mock
# of relevant Alchemy namespaces to get tests to pass until Alchemy AMQ
# is released.
#
# Without being able to see bits of Alchemy code that this minimally
# mocks, neither this file nor the tests that run through it will make
# much sense unfortunately.

require 'ostruct'
require 'msgpack'

module AlchemyAMQ
  class HTTPResponse < OpenStruct
  end

  class Message < OpenStruct
    def serialize
      self.payload = MessagePack.pack(@content)
    end

    def deserialize
      @content = MessagePack.unpack(self.payload, :symbolize_keys => true)
    end

    def send_message; end

    def self.register_type( *args ); end
  end
end
