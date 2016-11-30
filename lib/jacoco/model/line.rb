require 'happymapper'
require 'jacoco/model/counter'
require 'jacoco/model/method'

module Jacoco
  # Jacoco line model
  class Line
    include HappyMapper

    tag 'line'

    attribute :line_number, Integer, tag: 'nr'
    attribute :missed_instructions, Integer, tag: 'mi'
    attribute :covered_instructions, Integer, tag: 'ci'
    attribute :missed_branches, Integer, tag: 'mb'
    attribute :covered_branches, Integer, tag: 'cb'
  end
end
