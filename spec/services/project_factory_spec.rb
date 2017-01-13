require "rails_helper"
describe ProjectFactory do
  it "should instantiate a valid project" do
    project = ProjectFactory.new.build(
      dhis2_url:  "http://play.dhis2.org/demo",
      user:       "admin",
      password:   "district",
      bypass_ssl: false,
      program:    Program.build(code: "siera")
    )
    project.valid?
    project.dump_validations
    expect(project.errors.full_messages).to eq []
  end
end
