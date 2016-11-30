require 'happymapper'
require 'jacoco/model/session_info'

module Jacoco
  # Jacoco report model
  class Report
    include HappyMapper

    tag 'report'
    attribute :name, String

    has_many :session_infos, Jacoco::SessionInfo, xpath: '.'
    has_many :groups, Jacoco::Group, xpath: '.'
    has_many :packages, Jacoco::Package, xpath: '.'
    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
