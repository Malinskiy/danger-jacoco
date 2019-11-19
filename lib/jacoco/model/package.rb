# frozen_string_literal: true

require 'happymapper'
require 'jacoco/model/class'
require 'jacoco/model/sourcefile'

module Jacoco
  # Jacoco package model
  class Package
    include HappyMapper

    tag 'package'

    attribute :name, String
    has_many :sourcefiles, Jacoco::Sourcefile, xpath: '.'
    has_many :class_names, Jacoco::Class, xpath: '.'
    has_many :counters, Jacoco::Counter, xpath: '.'
  end
end
