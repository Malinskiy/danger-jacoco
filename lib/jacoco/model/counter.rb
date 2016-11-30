require 'happymapper'

module Jacoco
  # Jacoco counter model
  class Counter
    include HappyMapper

    tag 'counter'

    attribute :type, String
    attribute :missed, Integer
    attribute :covered, Integer
  end
end
