# frozen_string_literal: true

require 'jacoco/sax_parser'

module Danger
  # Verify code coverage inside your projects
  # This is done using the jacoco output
  # Results are passed out as a table in markdown
  #
  # @example Verify coverage
  #          jacoco.minimum_project_coverage_percentage = 50
  #
  # @example Verify coverage per package
  #          jacoco.minimum_package_coverage_map = { # optional (default is empty)
  #           'com/package/' => 55,
  #           'com/package/more/specific/' => 15
  #          }
  #
  # @see  Anton Malinskiy/danger-jacoco
  # @tags jacoco, coverage, java, android, kotlin
  #
  class DangerJacoco < Plugin # rubocop:disable Metrics/ClassLength
    attr_accessor :aspirational_project_coverage_percentage,
                  :aspirational_class_coverage_percentage,
                  :enforced_project_coverage_percentage,
                  :enforced_class_coverage_percentage,
                  :aspirational_package_coverage_map,
                  :aspirational_class_coverage_map,
                  :enforced_package_coverage_map,
                  :enforced_class_coverage_map,
                  :fail_no_coverage_data_found,
                  :files_extension,
                  :title

    # Initialize the plugin with configured parameters or defaults
    def setup
      @aspirational_project_coverage_percentage = 0 unless aspirational_project_coverage_percentage
      @aspirational_class_coverage_percentage = 0 unless aspirational_class_coverage_percentage
      @enforced_project_coverage_percentage = 0 unless enforced_project_coverage_percentage
      @enforced_class_coverage_percentage = 0 unless enforced_class_coverage_percentage
      @aspirational_package_coverage_map = {} unless aspirational_package_coverage_map
      @aspirational_class_coverage_map = {} unless aspirational_class_coverage_map
      @enforced_package_coverage_map = {} unless enforced_package_coverage_map
      @enforced_class_coverage_map = {} unless enforced_class_coverage_map
      @files_extension = ['.kt', '.java'] unless files_extension
      @title = 'JaCoCo' unless title
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
    # @report_url URL where html report hosted
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
    def report(path, report_url = '', delimiter = %r{/java/|/kotlin/|/scala/}, fail_no_coverage_data_found: true)
      @fail_no_coverage_data_found = fail_no_coverage_data_found

      setup
      classes = classes(delimiter)

      parser = Jacoco::SAXParser.new(classes)
      Nokogiri::XML::SAX::Parser.new(parser).parse(File.open(path))

      total_covered = total_coverage(path)

      report_markdown = "### #{title} Code Coverage #{total_covered[:covered]}% #{total_covered[:status]}\n"
      report_markdown += "| Class | Coverage | Enforced | Aspirational | Status |\n"
      report_markdown += "|:---|:---:|:---:|:---:|:---:|\n"
      class_coverage_above_minimum = markdown_class(parser, report_markdown, report_url)
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
      report_result = {
        coverage: 'No coverage data found : -',
        status: ':black_joker:',
        enforced_coverage: 'No coverage data found : -',
        aspirational_coverage: 'No coverage data found : -'
      }

      counter = coverage_counter(jacoco_class)
      unless counter.nil?
        coverage = (counter.covered.fdiv(counter.covered + counter.missed) * 100).floor
        enforced_class_coverage = enforced_class_coverage(jacoco_class)
        aspirational_class_coverage = aspirational_class_coverage(jacoco_class)
        status = coverage_status(coverage, enforced_class_coverage, aspirational_class_coverage)

        report_result = {
          coverage: coverage,
          status: status,
          enforced_coverage: enforced_class_coverage,
          aspirational_coverage: aspirational_class_coverage
        }
      end

      report_result
    end

    # it returns the most suitable coverage by package name to class or nil
    def package_coverage(class_name)
      path = class_name
      package_parts = class_name.split('/')
      package_parts.reverse_each do |item|
        size = item.size
        path = path[0...-size]
        coverage = enforced_package_coverage_map[path]
        path = path[0...-1] unless path.empty?
        return coverage unless coverage.nil?
      end
      nil
    end

    # it returns an emoji for coverage status
    def coverage_status(coverage, enforced_coverage, aspirational_coverage)
      if coverage < enforced_coverage then ':skull:'
      elsif coverage < aspirational_coverage then ':warning:'
      else
        ':white_check_mark:'
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
      coverage_status = coverage_status(
        covered_percentage,
        enforced_project_coverage_percentage,
        aspirational_project_coverage_percentage
      )

      {
        covered: covered_percentage,
        status: coverage_status
      }
    end

    private
    #
    # A function
    #
    # Params:
    # +jacoco_class+:: The c
    #
    # Returns:
    #   The enforced coverage percentage for the class based on the configurations of
    def enforced_class_coverage(jacoco_class)
      key = enforced_class_coverage_map.keys.detect { |k| jacoco_class.name.match(k) } || jacoco_class.name
      enforced_coverage = enforced_class_coverage_map[key]
      enforced_coverage = package_coverage(jacoco_class.name) if enforced_coverage.nil?
      enforced_coverage = enforced_class_coverage_percentage if enforced_coverage.nil?
      enforced_coverage
    end

    # Determines the required coverage for the class
    def aspirational_class_coverage(jacoco_class)
      key = aspirational_class_coverage_map.keys.detect { |k| jacoco_class.name.match(k) } || jacoco_class.name
      aspirational_coverage = aspirational_class_coverage_map[key]
      aspirational_coverage = package_coverage(jacoco_class.name) if aspirational_coverage.nil?
      aspirational_coverage = aspirational_class_coverage_percentage if aspirational_coverage.nil?
      aspirational_coverage
    end

    def coverage_counter(jacoco_class)
      counters = jacoco_class.counters
      branch_counter = counters.detect { |e| e.type.eql? 'BRANCH' }
      line_counter = counters.detect { |e| e.type.eql? 'LINE' }
      counter = branch_counter.nil? ? line_counter : branch_counter

      if counter.nil?
        no_coverage_data_found_message = "No coverage data found for #{jacoco_class.name}"

        raise no_coverage_data_found_message if @fail_no_coverage_data_found.instance_of?(TrueClass)

        warn no_coverage_data_found_message
      end

      counter
    end

    # rubocop:disable Style/SignalException
    def report_fails(class_coverage_above_minimum, total_covered)
      if total_covered[:covered] < enforced_project_coverage_percentage
        # fail danger if total coverage is smaller than minimum_project_coverage_percentage
        covered = total_covered[:covered]
        fail("Total coverage of #{covered}%. Improve this to at least #{enforced_project_coverage_percentage}%")
      end

      return if class_coverage_above_minimum

      fail("Class coverage is below minimum. Improve to at least #{enforced_class_coverage_percentage}%")
    end
    # rubocop:enable Style/SignalException

    def markdown_class(parser, report_markdown, report_url)
      class_coverage_above_minimum = true
      parser.classes.each do |jacoco_class| # Check metrics for each classes
        rp = report_class(jacoco_class)
        rl = report_link(jacoco_class.name, report_url)
        ln = "| #{rl} | #{rp[:coverage]}% | #{rp[:enforced_coverage]}% | #{rp[:aspirational_coverage]}% | #{rp[:status]} |\n"
        report_markdown << ln

        class_coverage_above_minimum &&= rp[:coverage] >= rp[:enforced_coverage]
      end

      class_coverage_above_minimum
    end

    def report_link(class_name, report_url)
      if report_url.empty?
        "`#{class_name}`"
      else
        report_filepath = "#{class_name.gsub(%r{/(?=[^/]*/.)}, '.')}.html"
        "[`#{class_name}`](#{report_url + report_filepath})"
      end
    end
  end
end
