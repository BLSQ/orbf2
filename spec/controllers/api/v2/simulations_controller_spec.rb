require 'rails_helper'

RSpec.describe Api::V2::SimulationsController, type: :controller do
  let(:program) { create :program }
  let(:project_anchor) { create :project_anchor, token: token, program: program }
  let(:token) { "123456789" }
  let(:orgunitid) { "orgunitid" }
  let(:period) { "2016Q1" }

  describe "#index" do
    it 'returns all simulations for project anchor' do
      (1..3).each do |i|
        project_anchor.invoicing_simulation_jobs.create(
          orgunit_ref: orgunitid + "_#{i}",
          dhis2_period: period
        )
      end
      get(:index, params: { token: token })
      resp = JSON.parse(response.body)
      expect(resp["data"].length).to eq(3)
    end

    it 'has an order' do
      (1..3).each do |i|
        project_anchor.invoicing_simulation_jobs.create(
          orgunit_ref: orgunitid + "_#{i}",
          dhis2_period: period
        )
      end
      get(:index, params: { token: token })
      resp = JSON.parse(response.body)

      expected_order = project_anchor.invoicing_simulation_jobs.order(updated_at: :desc).pluck(:id).map(&:to_s)
      received_order = resp["data"].map{|h| h["id"]}
      expect(received_order).to eq(expected_order)
    end
  end

  describe "#show" do
    it "returns simulation job based on id" do
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
      expect(resp["errors"].first["status"]).to eq("404")
    end
  end

  describe "#query_based_show" do
    include_context "basic_context"

    let(:project) {
      project = full_project
      project.project_anchor.update_attributes(token: token)
      project.save!
      project
    }

    it 'errors on invalid params' do
      token = project.project_anchor.token
      get(:query_based_show, params: { token: token })

      expect(response.status).to eq(400)
      resp = JSON.parse(response.body)
      expect(resp["errors"].first["detail"]).to include("Missing")
    end

    it 'shows the matching one' do
      token = project.project_anchor.token
      org_ref = "abc123"
      period = "2019Q1"
      allow(InvoiceSimulationWorker).to receive(:perform_async)
      simulation_job = project.project_anchor.invoicing_simulation_jobs.create(orgunit_ref: org_ref, dhis2_period: period)
      get(:query_based_show, params: { token: token, orgUnit: org_ref, periods: period })
      resp = JSON.parse(response.body)
      expect(resp["data"]["id"]).to eq(simulation_job.id.to_s)
    end

    it 'creates a new one when not existing yet' do
      token = project.project_anchor.token
      org_ref = "abc123"
      period = "2019Q4"
      allow(InvoiceSimulationWorker).to receive(:perform_async)
      get(:query_based_show, params: { token: token, orgUnit: org_ref, periods: period })
      resp = JSON.parse(response.body)
      job = project.project_anchor.invoicing_simulation_jobs.first
      expect(resp["data"]["id"]).to eq(job.id.to_s)
      expect(resp["meta"]["was_enqueued"]).to eq(true)
    end

    it 'enqueues a new job for a new one' do
      token = project.project_anchor.token
      org_ref = "abc123"
      period = "2019Q4"
      expected = [
        "abc123",
        "2019Q4",
        project.id,
        nil,
        project.engine_version,
        nil,
        nil
      ]
      expect(InvoiceSimulationWorker).to receive(:perform_async).with(*expected)
      get(:query_based_show, params: { token: token, orgUnit: org_ref, periods: period })
      expect(response.status).to eq(200)
    end

  end
end
