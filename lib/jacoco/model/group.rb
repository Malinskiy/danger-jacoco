require 'happymapper'
require 'jacoco/model/group'
require 'jacoco/model/package'
require 'jacoco/model/counter'

module Jacoco
  # Jacoco group model
  class Group
    include HappyMapper

    tag 'group'

    attribute :name, String
    has_many :groups, Jacoco::Group, xpath: '.'
    has_many :packages, Jacoco::Package, xpath: '.'
    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
