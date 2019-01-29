require File.expand_path("../spec_helper", __FILE__)

module Danger

  describe Danger::DangerJacoco do
    it "should be a plugin" do
      expect(Danger::DangerJacoco.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.jacoco

        modified_files = ['src/java/com/example/CachedRepository.java']
        added_files = ['src/java/Blah.java']

        allow(@dangerfile.git).to receive(:modified_files).and_return(modified_files)
        allow(@dangerfile.git).to receive(:added_files).and_return(added_files)

      end


      it :report do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_class_coverage_map = { "com/example/CachedRepository" => 100}

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:errors]).to eq(["Total coverage of 32.9%. Improve this to at least 50%",
                                                          "Class coverage is below minimum. Improve to at least 0%"])
        expect(@dangerfile.status_report[:markdowns][0].message).to include("### JaCoCO Code Coverage 32.9% :warning:")
        expect(@dangerfile.status_report[:markdowns][0].message).to include("| Class | Covered | Meta | Status |")
        expect(@dangerfile.status_report[:markdowns][0].message).to include("|:---|:---:|:---:|:---:|")
        expect(@dangerfile.status_report[:markdowns][0].message).to include("| com/example/CachedRepository | 50% | 100% | :warning: |")

      end

    end
  end
end
