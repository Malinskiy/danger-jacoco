require 'jacoco/sax_parser'

module Danger
  #
  # @see  Anton Malinskiy/danger-jacoco
  # @tags jacoco, coverage, java, android
  #
  class DangerJacoco < Plugin
    attr_accessor :minimum_coverage_percentage

    # Parses the xml output of jacoco to Ruby model classes
    # This is slow since it's basically DOM parsing
    #
    # @path path to the xml output of jacoco
    #
    def parse(path)
      Jacoco::DOMParser.read_path(path)
    end

    # This is a fast report based on SAX parser
    #
    # @path path to the xml output of jacoco
    # @delimiter git.modified_files returns full paths to the
    # changed files. We need to get the java class from this path to check the
    # Jacoco report,
    #
    # e.g. src/java/com/example/SomeClass.java -> com/example/SomeClass
    #
    # The default value supposes that you're using gradle structure,
    # that is your path to java source files is something like
    #
    # blah/blah/java/slashed_package/Source.java
    #
    def report(path, delimiter = '/java/')
      classes = classes(delimiter)

      parser = Jacoco::SAXParser.new(classes)
      Nokogiri::XML::SAX::Parser.new(parser).parse(File.open(path))

      parser.classes.each do |jacoco_class|
        # Check which metrics are available
        report_class(jacoco_class)
      end
    end

    def classes(delimiter)
      git = @dangerfile.git
      affected_files = git.modified_files + git.added_files
      affected_files.select { |file| file.end_with? '.java' }
                    .map { |file| extract_class(file, delimiter) }
    end

    def report_class(jacoco_class)
      counters       = jacoco_class.counters
      branch_counter = counters.detect { |e| e.type.eql? 'BRANCH' }
      line_counter   = counters.detect { |e| e.type.eql? 'LINE' }
      counter        = branch_counter.nil? ? line_counter : branch_counter

      report_counter(counter, jacoco_class)
    end

    def report_counter(counter, jacoco_class)
      covered  = counter.covered
      missed   = counter.missed
      coverage = (covered.fdiv(covered + missed) * 100).floor

      return unless coverage < minimum_coverage_percentage

      fail("#{jacoco_class.name} has coverage of #{coverage}%. " \
              "Improve this to at least #{minimum_coverage_percentage}%")
    end

    def extract_class(file, java_path_delimiter)
      file[0, file.length - 5].split(java_path_delimiter)[1]
    end
  end
end
