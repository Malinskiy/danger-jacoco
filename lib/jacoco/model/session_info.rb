require 'happymapper'

module Jacoco
  # Jacoco sessioninfo model
  class SessionInfo
    include HappyMapper

    tag 'sessioninfo'

    attribute :id, String
    attribute :start, Integer
    attribute :dump, Integer
  end
end
