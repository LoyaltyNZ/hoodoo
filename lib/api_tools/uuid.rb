require "uuidtools"

module ApiTools
  class UUID

    UUID_LENGTH = 32

    def self.generate
      UUIDTools::UUID.random_create.to_i.to_s(16).ljust(UUID_LENGTH,'0')
    end
  end
end