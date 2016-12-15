require "rails_helper"
describe ProjectFactory::InvoiceBuilder do
  it "should instantiate a valid project" do
    project = ProjectFactory.new.build
    project.valid?
    expect(project.errors.full_messages).to eq ''
  end
end
