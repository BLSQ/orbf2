require "rails_helper"
require "data_test"

def artefact(name)
  JSON.parse(File.open(File.join(DataTest::ARTEFACT_DIR, name)).read)
end

def result(name)
  JSON.parse(File.open(File.join(DataTest::RESULTS_DIR,name)).read)
end

RSpec.describe "Data Test", data_test: true do
  if DataTest::Fetcher.can_run?
    before(:all) do
      if DataTest.has_artefacts?
        puts "Artefacts found (no new download)"
      else
        puts "Downloading artefacts"
        WebMock.allow_net_connect!
        fetcher = DataTest::Fetcher.new
        fetcher.fetch_all_artefacts
        WebMock.disable_net_connect!
      end
    end

    after(:all) do
      puts "Clearing artefacts"
      DataTest.clear_artefacts! unless DataTest.keep_artefacts?
    end

    DataTest.all_cases.each do |name, subject|
      describe "#{name}" do
        before(:all) do
          puts "  -> Running simulation and saving data"
          DataTest::Verifier.new(subject).call
        end

        it "problem" do
          original = artefact("#{name}-problem.json")
          new = result("#{name}-problem.json")
          result = JsonDiff.diff(original, new, include_was: true)
          unless result.empty?
            puts "  + original: #{original.keys.count} vs new: #{new.keys.count}"
            puts "  + diff (first 10): #{result.sample(10)}"
          end
          expect(result).to be_empty
        end

        it "solution" do
          original = artefact("#{name}-solution.json")
          new = result("#{name}-solution.json")
          result = JsonDiff.diff(original, new, include_was: true)
          unless result.empty?
            puts "  + original: #{original.keys.count} vs new: #{new.keys.count}"
            puts "  + diff (first 10): #{result.sample(10)}"
          end
          expect(result).to be_empty
        end

        it "exported_values" do
          original = artefact("#{name}-exported_values.json")
          new = result("#{name}-exported_values.json")
          diff = HashDiff.diff(original, new, use_lcs: false)
          unless diff.empty?
            puts "  + original: #{original.count} vs new: #{new.count}"
            puts "  + diff (first 10): #{diff.sample(10)}"
          end
          expect(diff).to be_empty
        end
      end
    end
  else
    message = <<DESC
No FETCHER_S3_ACCESS and FETCHER_S3_KEY found in ENV-variables.

These are needed to download the artefacts to verify the results with,
so now skipping.
DESC
    if ENV["CI"]
      it 'has S3 configured' do
        fail message
      end
    else
      puts message
    end
  end
end
