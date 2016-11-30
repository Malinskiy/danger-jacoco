require 'happymapper'

module Jacoco
  # Jacoco sourcefile model
  class Sourcefile
    include HappyMapper

    tag 'sourcefile'

    attribute :name, String

    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
