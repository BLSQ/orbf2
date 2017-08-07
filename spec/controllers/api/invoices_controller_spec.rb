require "rails_helper"

RSpec.describe Api::InvoicesController, type: :controller do
  describe "When post create" do
    let(:program) { create :program }
    let(:project_anchor) { create :project_anchor, token: token, program: program }
    let(:token) { "123456789" }
    let(:orgunitid) { "orgunitid" }

    it "should schedule invoice for a given period, ou" do
      post :create, params: { pe: "201612", token: project_anchor.token, ou: orgunitid }
      expect(response.body).to eq({ project_anchor: 1 }.to_json)
      expect(InvoiceForProjectAnchorWorker).to have_enqueued_sidekiq_job(
        project_anchor.id, 2016, 4, [orgunitid]
      )
    end
  end
end
