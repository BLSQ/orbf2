# frozen_string_literal: true
# == Schema Information
#
# Table name: projects
#
#  id                    :bigint(8)        not null, primary key
#  boolean               :boolean          default(FALSE)
#  bypass_ssl            :boolean          default(FALSE)
#  calendar_name         :string           default("gregorian"), not null
#  cycle                 :string           default("quarterly"), not null
#  default_aoc_reference :string
#  default_coc_reference :string
#  dhis2_logs_enabled    :boolean          default(TRUE), not null
#  dhis2_url             :string           not null
#  enabled               :boolean          default(TRUE), not null
#  engine_version        :integer          default(3), not null
#  invoice_app_path      :string           default("/api/apps/ORBF2---Invoices-and-Reports/index.html"), not null
#  name                  :string           not null
#  password              :string
#  publish_date          :datetime
#  publish_end_date      :datetime
#  qualifier             :string
#  read_through_deg      :boolean          default(TRUE), not null
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
  describe "#publishing and for_date" do
    let(:project_anchor) {
      project_anchor = program.build_project_anchor
      project_anchor.save!
      project_anchor
    }
    let!(:project_v1) {
      create(:project, project_anchor: project_anchor, status: "published",
                                publish_date: DateTime.new(2012, 1, 1, 0, 0, 0),
                                publish_end_date: DateTime.new(2012, 12, 31, 23, 59, 59))
    }
    let!(:project_v2) {
      create(:project, project_anchor: project_anchor, status: "published",
                                publish_date: DateTime.new(2013, 1, 1, 0, 0, 0),
                                publish_end_date: DateTime.new(2014, 12, 31, 23, 59, 59))
    }
    let!(:project_draft) { create(:project, project_anchor: project_anchor, status: "draft") }

    def print(project, period)
      if project
        puts [period, " => ", project.id, project.publish_date, project.publish_end_date].map(&:to_s).join("\t")
      else
        puts period + "   => nil"
      end
    end

    def expect_project(period, expected_project)
      period_end_date = Periods.from_dhis2_period(period).end_date
      project = Project.for_date(period_end_date)
      print(project, period)
      expect(project).to eq(expected_project)
    end

    it "locates the correct project for a date" do
      expect_project("2012Q1", project_v1)
      expect_project("2012Q2", project_v1)
      expect_project("2012Q3", project_v1)
      expect_project("2012Q4", project_v1)
      expect_project("2013Q1", project_v2)
      expect_project("2013Q2", project_v2)
      expect_project("2014Q3", project_v2)
      expect_project("2014Q4", project_v2)
      expect_project("2015Q1", nil)
    end
  end
end
