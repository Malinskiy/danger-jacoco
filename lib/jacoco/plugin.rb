require 'jacoco/sax_parser'

module Danger
  #
  # @see  Anton Malinskiy/danger-jacoco
  # @tags jacoco, coverage, java, android, kotlin
  #
  class DangerJacoco < Plugin
    attr_accessor :minimum_project_coverage_percentage
    attr_accessor :minimum_class_coverage_percentage
    attr_accessor :files_extension
    attr_accessor :minimum_class_coverage_map

    def setup
      @minimum_project_coverage_percentage = 0 unless minimum_project_coverage_percentage
      @minimum_class_coverage_percentage = 0 unless minimum_class_coverage_percentage
      @minimum_class_coverage_map = {} unless minimum_class_coverage_map
      @files_extension = ['.kt', '.java'] unless files_extension
    end

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
    # changed files. We need to get the class from this path to check the
    # Jacoco report,
    #
    # e.g. src/java/com/example/SomeJavaClass.java -> com/example/SomeJavaClass
    # e.g. src/kotlin/com/example/SomeKotlinClass.kt -> com/example/SomeKotlinClass
    #
    # The default value supposes that you're using gradle structure,
    # that is your path to source files is something like
    #
    # Java => blah/blah/java/slashed_package/Source.java
    # Kotlin => blah/blah/kotlin/slashed_package/Source.kt
    #
    def report(path, delimiter = %r{\/java\/|\/kotlin\/})
      setup
      classes = classes(delimiter)

      parser = Jacoco::SAXParser.new(classes)
      Nokogiri::XML::SAX::Parser.new(parser).parse(File.open(path))

      total_covered = total_coverage(path)

      report_markdown = "### JaCoCO Code Coverage #{total_covered[:covered]}% #{total_covered[:status]}\n"
      report_markdown << "| Class | Covered | Meta | Status |\n"
      report_markdown << "|:---|:---:|:---:|:---:|\n"
      class_coverage_above_minimum = markdown_class(parser, report_markdown)
      markdown(report_markdown)

      report_fails(class_coverage_above_minimum, total_covered)
    end

    # Select modified and added files in this PR
    def classes(delimiter)
      git = @dangerfile.git
      affected_files = git.modified_files + git.added_files
      affected_files.select { |file| files_extension.reduce(false) { |state, el| state || file.end_with?(el) } }
                    .map { |file| file.split('.').first.split(delimiter)[1] }
    end

    # It returns a specific class code coverage and an emoji status as well
    def report_class(jacoco_class)
      counter = coverage_counter(jacoco_class)
      coverage = (counter.covered.fdiv(counter.covered + counter.missed) * 100).floor
      required_coverage = minimum_class_coverage_map[jacoco_class.name]
      required_coverage = minimum_class_coverage_percentage if required_coverage.nil?
      status = coverage_status(coverage, required_coverage)

      {
        covered: coverage,
        status: status,
        required_coverage_percentage: required_coverage
      }
    end

    # it returns an emoji for coverage status
    def coverage_status(coverage, minimum_percentage)
      if coverage < (minimum_percentage / 2) then ':skull:'
      elsif coverage < minimum_percentage then ':warning:'
      else ':white_check_mark:'
      end
    end

    # It returns total of project code coverage and an emoji status as well
    def total_coverage(report_path)
      jacoco_report = Nokogiri::XML(File.open(report_path))

      report = jacoco_report.xpath('report/counter').select { |item| item['type'] == 'INSTRUCTION' }
      missed_instructions = report.first['missed'].to_f
      covered_instructions = report.first['covered'].to_f
      total_instructions = missed_instructions + covered_instructions
      covered_percentage = (covered_instructions * 100 / total_instructions).round(2)
      coverage_status = coverage_status(covered_percentage, minimum_project_coverage_percentage)

      {
        covered: covered_percentage,
        status: coverage_status
      }
    end

    private

    def coverage_counter(jacoco_class)
      counters = jacoco_class.counters
      branch_counter = counters.detect { |e| e.type.eql? 'BRANCH' }
      line_counter = counters.detect { |e| e.type.eql? 'LINE' }
      counter = branch_counter.nil? ? line_counter : branch_counter
      raise "No coverage data found for #{jacoco_class.name}" if counter.nil?

      counter
    end

    # rubocop:disable Style/SignalException
    def report_fails(class_coverage_above_minimum, total_covered)
      if total_covered[:covered] < minimum_project_coverage_percentage
        # fail danger if total coverage is smaller than minimum_project_coverage_percentage
        covered = total_covered[:covered]
        fail("Total coverage of #{covered}%. Improve this to at least #{minimum_project_coverage_percentage}%")
      end

      return if class_coverage_above_minimum

      fail("Class coverage is below minimum. Improve to at least #{minimum_class_coverage_percentage}%")
    end
    # rubocop:enable Style/SignalException

    def markdown_class(parser, report_markdown)
      class_coverage_above_minimum = true
      parser.classes.each do |jacoco_class| # Check metrics for each classes
        rp = report_class(jacoco_class)
        ln = "| #{jacoco_class.name} | #{rp[:covered]}% | #{rp[:required_coverage_percentage]}% | #{rp[:status]} |\n"
        report_markdown << ln

        class_coverage_above_minimum &&= rp[:covered] >= rp[:required_coverage_percentage]
      end

      class_coverage_above_minimum
    end
  end
end
