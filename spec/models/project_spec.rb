# == Schema Information
#
# Table name: projects
#
#  id                    :integer          not null, primary key
#  boolean               :boolean          default(FALSE)
#  bypass_ssl            :boolean          default(FALSE)
#  cycle                 :string           default("quarterly"), not null
#  default_aoc_reference :string
#  default_coc_reference :string
#  dhis2_url             :string           not null
#  engine_version        :integer          default(1), not null
#  name                  :string           not null
#  password              :string
#  publish_date          :datetime
#  qualifier             :string
#  status                :string           default("draft"), not null
#  user                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  original_id           :integer
#  project_anchor_id     :integer
#
# Indexes
#
#  index_projects_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (original_id => projects.id)
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

require "rails_helper"

RSpec.describe Project, type: :model do
  include_context "basic_context"
  include WebmockDhis2Helpers

  it "enables paper trail" do
    is_expected.to be_versioned
  end

  let!(:project) { create(:project, project_anchor: program.build_project_anchor) }

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
