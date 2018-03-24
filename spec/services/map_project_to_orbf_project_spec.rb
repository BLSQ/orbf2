require "rails_helper"
RSpec.describe MapProjectToOrbfProject do
  include_context "basic_context"

  it "should instantiate a valid project" do
    project = full_project
    orbf_project = MapProjectToOrbfProject.new(project, []).map
    expect(orbf_project).to be_a(Orbf::RulesEngine::Project)
    expect(orbf_project.packages.first).to be_a(Orbf::RulesEngine::Package)
    expect(orbf_project.packages.size).to eq project.packages.size

    # dump with yaml to support circular references
    puts YAML.dump(orbf_project)
  end
end
