# frozen_string_literal: true

require 'happymapper'
require 'jacoco/model/counter'
require 'jacoco/model/method'

module Jacoco
  # Jacoco Class model
  class Class
    include HappyMapper

    tag 'class'

    attribute :name, String

    has_many :methods, Jacoco::Method, xpath: '.'
    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
