# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::InvoicesController, type: :controller do
  describe "When post create" do
    let(:program) { create :program }
    let(:project_anchor) { create :project_anchor, token: token, program: program }
    let(:token) { "123456789" }
    let(:orgunitid) { "orgunitid" }
    let(:period) { "201612" }

    it "should schedule invoice for a given period, ou" do
      post :create, params: {
        pe:    period,
        token: project_anchor.token,
        ou:    orgunitid
      }
      expect(response.body).to eq({ project_anchor: 1 }.to_json)
      expect(InvoiceForProjectAnchorWorker).to have_enqueued_sidekiq_job(
        project_anchor.id, 2016, 4, [orgunitid]
      )

      expect(job_attributes).to eq("dhis2_period"      => "2016Q4",
                                   "orgunit_ref"       => orgunitid,
                                   "project_anchor_id" => project_anchor.id,
                                   "status"            => "enqueued")
    end

    it "handle double schedule invoice for a given period, ou" do
      post :create, params: { pe: "201612", token: project_anchor.token, ou: orgunitid }
      before_job_attributes = job_attributes
      post :create, params: { pe: "201612", token: project_anchor.token, ou: orgunitid }
      expect(job_attributes).to eq(before_job_attributes)
    end

    def job_attributes
      project_anchor.reload
      project_anchor.invoicing_jobs
                    .last
                    .attributes
                    .slice("project_anchor_id",
                           "orgunit_ref",
                           "orgunitid",
                           "dhis2_period",
                           "status")
    end
  end
end
