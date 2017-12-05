require 'nokogiri'

module Jacoco
  # Sax parser for quickly finding class elements in Jacoco report
  class SAXParser < Nokogiri::XML::SAX::Document
    attr_accessor :class_names
    attr_accessor :classes

    def initialize(classes)
      @class_names      = classes
      @classes          = []
      @current_class    = nil
      @subelement_index = 0
    end

    def start_element(name, attrs = [])
      case name
      when 'class'
        start_class(attrs)
      when 'counter'
        start_counter(attrs)
      end

      @subelement_index += 1
    end

    def start_counter(attrs)
      return unless !@current_class.nil? && @subelement_index == 1

      counter         = Jacoco::Counter.new
      counter.type    = Hash[attrs]['type']
      counter.missed  = Hash[attrs]['missed'].to_i
      counter.covered = Hash[attrs]['covered'].to_i

      @current_class.counters.push(counter)
    end

    def start_class(attrs)
      @subelement_index = 0

      if @class_names.include?(Hash[attrs]['name'])
        c              = Jacoco::Class.new
        c.name         = Hash[attrs]['name']
        c.counters     = []
        @current_class = c
        @classes.push c
      elsif @current_class.nil?
      end
    end

    def characters(string); end

    def end_element(name)
      @subelement_index -= 1
      @current_class = nil if name.eql? 'class'
    end
  end
end
