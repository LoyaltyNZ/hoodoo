require "uuidtools"

module ApiTools
  class UUID
    def self.generate
      UUIDTools::UUID.random_create.to_i.to_s(16).ljust(32,'0')
    end
  end
end