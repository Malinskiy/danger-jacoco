# frozen_string_literal: true

require 'happymapper'
require 'jacoco/model/counter'

module Jacoco
  # Jacoco method model
  class Method
    include HappyMapper

    tag 'method'
    attribute :name, String
    attribute :desc, String
    attribute :line, Integer

    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
