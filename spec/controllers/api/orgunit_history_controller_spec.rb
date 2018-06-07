require "rails_helper"
require_relative "../../workers/dhis2_snapshot_fixture"

RSpec.describe Api::OrgunitHistoryController, type: :controller do
  include Dhis2SnapshotFixture
  include_context "basic_context"

  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:token) { "123456789" }
  let(:orgunitid) { "orgunitid" }

  let(:project) do
    project = full_project
    project.project_anchor = project_anchor
    project.save!
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!
    user.save!
    user.program = program
    project
  end

  let(:expected_period) {
    {
      "id"                     => "vRC0stJ5y9Q",
      "name"                   => "Bucksal Clinic",
      "period"                 => {
        "year"       => 2018,
        "month"      => 1,
        "dhis2"      => "201801",
        "start_date" => "2018-01-01",
        "end_date"   => "2018-01-31"
      },
      "ancestors"              => [
        {
          "id"    => "ImspTQPwCqd",
          "name"  => "Sierra Leone",
          "level" => 1
        },
        {
          "id"    => "O6uvpzGd5pu",
          "name"  => "Bo",
          "level" => 2
        },
        {
          "id"    => "U6Kr7Gtpidn",
          "name"  => "Kakua",
          "level" => 3
        }
      ],
      "organisationUnitGroups" => [
        {
          "id"   => "RXL3lPSK8oG",
          "name" => "Clinic"
        },
        {
          "id"   => "MAs88nJc9nL",
          "name" => "Private Clinic"
        },
        {
          "id"   => "oRVt7g429ZO",
          "name" => "Public facilities"
        },
        {
          "id"   => "GGghZsfu7qV",
          "name" => "Rural"
        }
      ],
      "contractGroup"          => [

      ],
      "contractMembers"        => [

      ]
    }
  }

  describe "When get group history" do
    it "return a list" do
      create_snaphots(project, "201801")
      get :index, params: {
        periods:           "2018Q1",
        token:             project.project_anchor.token,
        reference_period:  "201805",
        organisationUnits: "vRC0stJ5y9Q"
      }
      expect(JSON.parse(response.body)["organisationUnits"].first).to eq(expected_period)
    end
  end

  describe "patch" do
    it "patches existing snapshots" do
      create_snaphots(project, "201801")
      create_snaphots(project, "201802")
      create_snaphots(project, "201803")
      patch :apply, params: {
        periods:          ["201802","201803"],
        token:            project.project_anchor.token,
        reference_period: expected_period
      }
      puts JSON.pretty_generate(JSON.parse(response.body))
    end
  end

  def create_snaphots(project, month)
    stub_organisation_unit_group_sets(project)
    stub_organisation_unit_groups(project)
    stub_organisation_units(project)
    stub_system_info(project)

    Dhis2SnapshotWorker.new.perform(
      project.project_anchor.id,
      filter: %w[
        organisation_unit_group_sets
        organisation_unit_groups
        organisation_units
      ],
      now:    Periods.from_dhis2_period(month).end_date
    )
    WebMock.reset!
  end
end
