require File.expand_path('../spec_helper', __FILE__)

module Jacoco
  describe Jacoco::DOMParser do
    path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

    describe 'read xml' do
      it 'reads report' do
        Jacoco::DOMParser.read_path(path_a)
      end
    end
  end
end
