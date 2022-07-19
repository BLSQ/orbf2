# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::CalculationsController, type: :controller do
  let(:program) { create :program }
  let(:token) { "123456789" }

  let(:project_without_packages) do
    project = build :project
    project.project_anchor = program.build_project_anchor(token: token)
    project.save!
    user.program = program
    user.save!
    user.reload
    project
  end

  def authenticated
    request.headers["Accept"] = "application/vnd.api+json;version=2"
    request.headers["X-Token"] = project_without_packages.project_anchor.token
    request.headers["X-Dhis2UserId"] = "aze123sdf"
  end

  describe "#create" do
    include_context "basic_context"
    before do
      authenticated
    end

    it "should evaluate a formula" do
      payload = {
        "token" => token, 
        "expression" => "if(declared < verified, verified * tarif, 0)",
        "values" => {
            "tarif" =>  "10",
            "verified" => "20",
            "declared" => "10"
          }
      }
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      expected_resp = {
        "status" => "ok",
       "expression" => "if(declared < verified, verified * tarif, 0)",
       "values" => {
              "tarif" =>  "10",
              "verified" => "20",
              "declared" =>"10"
       },
       "result" => "200"
     } 

      expect(resp).to eq(expected_resp)
    end

    it "should evaluate a formula with %{..._values}" do
      payload = {
        "token" => token, 
        "expression" => "SUM(%{subsides_values})",
        "values" => {
            "subsides_values" =>  "1,2,3"
          }
      }
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      expected_resp = {
        "status" => "ok",
        "expression" => "SUM(%{subsides_values})",
        "values" => {
            "subsides_values" =>  "1,2,3"
          },
       "result" => "6"
     } 

      expect(resp).to eq(expected_resp)
    end

    it "should return error in case of syntax problem" do
      payload = {
        "token" => token, 
        "expression" => "SUM(%{subsides_values}",
        "values" => {
            "subsides_values" =>  "1,2,3"
          }
      }
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      
      expected_resp = {
        "status"=> "error",
        "expression"=> "SUM(%{subsides_values}",
        "values"=> {
          "subsides_values" =>  "1,2,3"
        },
        "error" => "In equation expression Unbalanced parenthesis expression := SUM(1,2,3"
      } 

      expect(resp).to eq(expected_resp)
    end

    it "should return error in case of mathematical problem" do
      payload = {
        "token" => token, 
        "expression" => "a / b",
        "values" => {
            "a" => "1",
            "b" => "0"
          }
      }
      post(:create, params: payload)

      resp = JSON.parse(response.body)
      
      expected_resp = {
        "status"=> "error",
        "expression" => "a / b",
        "values" => {
            "a" => "1",
            "b" => "0"
          },
        "error" => "In equation expression Divide by zero expression := a / b"
      } 

      expect(resp).to eq(expected_resp)
    end
  end
end