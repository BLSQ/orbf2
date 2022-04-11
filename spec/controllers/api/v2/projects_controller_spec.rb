# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::ProjectsController, type: :controller do
  include_context "basic_context"

  let(:program) { create :program }
  let(:token) { "123456789" }
  let!(:project) do
    project = full_project
    project.project_anchor.update(token: token)
    project.save!
    project
  end

  describe "#show" do
    def with_correct_headers
      request.headers["Accept"] = "application/vnd.api+json;version=2"
      request.headers["X-Token"] = project.project_anchor.token
    end

    it "returns project" do
      with_correct_headers
      get(:show, params: {})
      resp = JSON.parse(response.body)

      expect(resp["data"]["id"]).to eq(project.id.to_s)
    end

    it "returns periods" do
      with_correct_headers
      get(:show, params: {})
      resp = JSON.parse(response.body)

      expect(resp["data"]["attributes"]["periods"]).to include("2016Q1")
    end

    it "returns project fully" do
      with_correct_headers
      get(:show, params: { profile: "full" })
      resp = JSON.parse(response.body)

      expect(resp["data"]["id"]).to eq(project.id.to_s)

      decision_table = resp["included"].select { |i| i["type"] == "decisionTable" }[0]

      expect(decision_table["attributes"]).to eq(
        "name" => nil,
        "content"     => "ignore:level_2,ignore:level_2_name,in:level_3,ignore:level_3_name,out:equity_bonus\nsYUYlnVx1xh,Adamaoua,GMC5DCK8AZT,NGAOUNDERE RURAL,29\nsYUYlnVx1xh,Adamaoua,nLmXJF0dRvQ,Ngaoundéré Urbain,28\nxdxTFCAsoWc,EST,FIlyPgAPt8k,ABONG MBANG,25\nxdxTFCAsoWc,EST,CCQ2yJyFQAS,BATOURI,34\nxdxTFCAsoWc,EST,tE03W4q27te,BERTOUA,23\nxdxTFCAsoWc,EST,UeEzrOGGfWr,BETARE OYA,41\nxdxTFCAsoWc,EST,fLGSn6852xo,DOUME,27\nxdxTFCAsoWc,EST,at6UHUQatSo,bb,12\nxdxTFCAsoWc,EST,U6Kr7Gtpidn,bb2,12\nxdxTFCAsoWc,EST,U6Kr7Gtpidn,bb2,12\n",
        "endPeriod"   => nil,
        "inHeaders"   => ["level_3"],
        "outHeaders"  => ["equity_bonus"],
        "startPeriod" => nil,
        "comment" => nil,
        "sourceUrl" => nil
      )
    end
  end
end
