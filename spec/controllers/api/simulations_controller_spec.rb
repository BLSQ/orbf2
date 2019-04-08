require 'rails_helper'

RSpec.describe Api::SimulationsController, type: :controller do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:token) { "123456789" }
  let(:orgunitid) { "orgunitid" }
  let(:period) { "2016Q1" }

  describe "#show" do
    it "returns simulation job" do
      simulation_job = project_anchor.invoicing_simulation_jobs.create(orgunit_ref: orgunitid + "_3", dhis2_period: period)
      get(:show, params: { token: token, id: simulation_job.id })
      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(simulation_job.id.to_s)
    end

    it "won't return normal invoicing job" do
      normal_job = project_anchor.invoicing_jobs.create(orgunit_ref: orgunitid + "_3", dhis2_period: period)
      get(:show, params: { token: token, id: normal_job.id })
      expect(response.status).to eq(404)
      resp = JSON.parse(response.body)
      expect(resp["status"]).to eq("404")
    end
  end
end
