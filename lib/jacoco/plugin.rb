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

    def setup
      @minimum_project_coverage_percentage = 0 unless minimum_project_coverage_percentage
      @minimum_class_coverage_percentage = 0 unless minimum_class_coverage_percentage
      @files_extension = [".kt",".java"] unless files_extension
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
    def report(path, delimiter = /\/java\/|\/kotlin\//)
      setup
      classes = classes(delimiter)

      parser = Jacoco::SAXParser.new(classes)
      Nokogiri::XML::SAX::Parser.new(parser).parse(File.open(path))
      
      total_covered = total_coverage(path)

      report_markdown = "### JaCoCO Code Coverage #{total_covered[:covered]}% #{total_covered[:status]}\n"
      report_markdown << "| Class | Covered | Meta | Status |\n"
      report_markdown << "|:---:|:---:|:---:|:---:|\n"
      parser.classes.each do |jacoco_class| # Check metrics for each classes
        rp = report_class(jacoco_class)
        report_markdown << "| `#{jacoco_class.name}` | #{rp[:covered]}% | #{minimum_class_coverage_percentage}% | #{rp[:status]} |\n"
      end  
      markdown(report_markdown)

      # fail danger if total coveraged is smaller than minimum_project_coverage_percentage
      if total_covered[:covered] < minimum_project_coverage_percentage
        fail("Total coverage of #{total_covered[:covered]}%. Improve this to as least #{minimum_project_coverage_percentage} %")
      end
    end

    # Select modified and added files in this PR
    def classes(delimiter)
      git = @dangerfile.git
      affected_files = git.modified_files + git.added_files
      affected_files.select { |file| files_extension.reduce(false) { |state, el| state or file.end_with?(el) } }
                    .map { |file| file.split(".").first.split(delimiter)[1] }
    end

    # It returns a specific class code coverage and an emoji status as well
    def report_class(jacoco_class)
      
      counters       = jacoco_class.counters
      branch_counter = counters.detect { |e| e.type.eql? 'BRANCH' }
      line_counter   = counters.detect { |e| e.type.eql? 'LINE' }
      counter        = branch_counter.nil? ? line_counter : branch_counter
      coverage = (counter.covered.fdiv(counter.covered + counter.missed) * 100).floor
      status = coverage_status(coverage, minimum_class_coverage_percentage)
      
      return {
        covered: coverage,
        status: status
      }
      
    end

    # it returns an emoji for coverage status
    def coverage_status(coverage, minimum_percentage)
      return case
      when coverage < (minimum_percentage/2);  ":skull:"
      when coverage < minimum_percentage;  ":warning:"
      else ":white_check_mark:"
      end
    end

    # It returns total of project code coverage and an emoji status as well
    def total_coverage(report_path)
        jacoco_report = Nokogiri::XML(File.open(report_path))
        
        report = jacoco_report.xpath('report/counter').select { |item| item['type'] == "INSTRUCTION" }
        missed_instructions = report.first['missed'].to_f
        covered_instructions = report.first['covered'].to_f
        total_instructions = missed_instructions + covered_instructions
        covered_percentage = (covered_instructions * 100 / total_instructions).round(2)
        coverage_status = coverage_status(covered_percentage, minimum_project_coverage_percentage)

        return {
          covered: covered_percentage,
          status: coverage_status
        }
    end
  end
end
