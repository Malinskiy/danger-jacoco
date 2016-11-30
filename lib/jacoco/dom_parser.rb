module Jacoco
  # DOM parser for Jacoco report
  class DOMParser
    def self.read_path(path)
      DOMParser.new.read_path(path)
    end

    def self.read_string(string)
      DOMParser.new.read_string(string)
    end

    def read_path(path)
      file = File.read(path)
      read_string(file)
    end

    def read_string(string)
      Report.parse(string)
    end
  end
end
