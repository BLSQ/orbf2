require "rails_helper"

RSpec.describe Project, type: :model do
  include_context "basic_context"
  include WebmockDhis2Helpers

  let!(:project) { create(:project) }

  it "should validate url " do
    expect(project.valid?).to eq true
    project.dhis2_url = "http:// bad : userexport@/dev:456.url"
    expect(project.valid?).to eq false
  end

  describe "#verify_connection" do
    it "should validate url before testing" do
      project.dhis2_url = "http:// bad : userexport@/dev:456.url"
      expect(project.verify_connection).to eq(
        status:  :ko,
        message: "Dhis2 url is not an url"
      )
    end

    it "should return ok when connection is ok" do
      stub_dhis2_system_info_success(project.dhis2_url)

      expect(project.verify_connection).to eq(
        status:  :ok,
        message: { "version"=>"2.25" }
      )
    end

    it "should return ko when connection is ko" do
      stub_dhis2_system_info_error(project.dhis2_url)

      expect(project.verify_connection).to eq(
        status:  :ko,
        message: "401 Unauthorized"
      )
    end
  end
end
