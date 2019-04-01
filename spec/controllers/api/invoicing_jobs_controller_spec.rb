# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::InvoicingJobsController, type: :controller do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:token) { "123456789" }
  let(:orgunitid) { "orgunitid" }
  let(:period) { "2016Q1" }

  let!(:invoicing_jobs) {
    [
      project_anchor.invoicing_jobs.create(orgunit_ref: orgunitid, dhis2_period: period),
      project_anchor.invoicing_jobs.create(orgunit_ref: orgunitid + "_2", dhis2_period: period),
      project_anchor.invoicing_jobs.create(orgunit_ref: orgunitid + "_3", dhis2_period: period)
    ]
  }

  describe "When post for search" do
    it "returns invoicing jobs" do
      post(:create, params: { token: token })
      resp = JSON.parse(response.body)
      expect(resp).to eq(
        "message" => "param is missing or the value is empty: period",
        "status"  => "KO"
      )
    end

    it "returns invoicing jobs" do
      post(:create, params: { token: token, period: period, orgUnits: orgunitid })
      resp = JSON.parse(response.body)
      expect(resp["data"][0]).to eq(
        "id"         => invoicing_jobs[0].id.to_s,
        "type"       => "invoicingJob",
        "attributes" =>
                        { "orgUnit"       => "orgunitid",
                          "dhis2Period"   => "2016Q1",
                          "user"          => nil,
                          "createdAt"     => invoicing_jobs[0].created_at.iso8601(3),
                          "processedAt"   => nil,
                          "erroredAt"     => nil,
                          "durationMs"    => nil,
                          "resultUrl"     => nil,
                          "status"        => nil,
                          "lastError"     => nil,
                          "sidekiqJobRef" => nil,
                          "isAlive"       => true }
      )
    end
  end

  describe "#index" do
    it "returns invoicing jobs" do
      simulation_job = project_anchor.invoicing_simulation_jobs.create(orgunit_ref: orgunitid + "_3", dhis2_period: period)
      get(:index, params: { token: token, period: period })
      resp = JSON.parse(response.body)
      expect(resp["data"].count).to eq(invoicing_jobs.count)
    end

    it "only returns invoicing jobs" do
      simulation_job = project_anchor.invoicing_simulation_jobs.create(orgunit_ref: orgunitid + "_3", dhis2_period: period)
      get(:index, params: { token: token, period: period })
      resp = JSON.parse(response.body)
      expect(resp["data"].map {|d| d["id"]}).to_not include(simulation_job.id)
    end
  end

end
