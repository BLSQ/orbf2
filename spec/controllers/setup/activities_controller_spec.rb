# frozen_string_literal: true

require "rails_helper"

RSpec.describe Setup::ActivitiesController, type: :controller do
  describe "When non authenticated #orgunitgroup" do
    it "should redirect to sign on" do
      get :new, params: { project_id: 1 }
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "When authenticated" do
    include_context "basic_context"

    before(:each) do
      sign_in user
    end

    let!(:project) { full_project }

    let(:state_id_1) { project.states.first.id }
    let(:state_id_2) { project.states.second.id }

    it "should return form for creation of a new activity" do
      get :new, params: { project_id: project.id }
      activity = assigns(:activity)
      expect(activity).not_to be_nil
    end

    it "should return form for edition of a new activity" do
      get :edit, params: { project_id: project.id, id: project.activities.first.id }
      activity = assigns(:activity)
      states = assigns(:states)
      expect(states.map(&:code)).to eq %w[
        claimed verified validated max_score
        tarif budget remoteness_bonus applicable_points waiver
      ]
      expect(activity).to eq project.activities.first
    end

    describe "#mass_creation" do
      it "should validate before creating " do
        get :mass_creation, params: { project_id: project.id }
        missing_activity_states = assigns(:missing_activity_states)
        expect(missing_activity_states.size).to eq 2
      end

      it "should create asynch the missing data element " do
        project.missing_activity_states.first
        activity_id = project.missing_activity_states.first.first.id
        state_id = project.missing_activity_states.first.last.first.id
        post :confirm_mass_creation, params: {
          project_id:  project.id,
          activity_id: activity_id,
          state_id:    state_id,
          name:        "long and descriptrive name",
          short_name:  "short name",
          code:        "code"
        }

        expect(CreateMissingDhis2ElementForActivityWorker).to have_enqueued_sidekiq_job(
          project.id,
          "activity_id"  => activity_id,
          "state_id"     => state_id,
          "data_element" => {
            "name"       => "long and descriptrive name",
            "short_name" => "short name",
            "code"       => "code"
          }
        )
      end
    end

    describe "#update" do
      it "should validate before creating " do
        expect do
          post :update, params: {
            project_id: project.id,
            id:         project.activities.first.id,
            activity:   {
              name:                       "",
              activity_states_attributes: [
                {
                  name:               "activity_state_name",
                  external_reference: "",
                  kind:               "data_element",
                  formula:            "1"
                }
              ]
            }
          }
        end.to_not change {
                     {
                       activity:        Activity.count,
                       activity_states: ActivityState.count
                     }
                   }
      end

      it "should add data elements with category option combo to activity states" do
        stub_request(:get, "http://play.dhis2.org/demo/api/dataElements?fields=id,name,categoryCombo%5Bid,name,categoryOptionCombos%5Bid,name%5D%5D&filter=id:in:%5BP3jJH5Tu5VC%5D")
          .to_return(status: 200, body: { "dataElements": [
            { "name" => "Acute Flaccid Paralysis (AFP) follow-up",
              "id" => "P3jJH5Tu5VC",
              "categoryCombo": { "name"                 => "Morbidity Age",
                                 "id"                   => "pbvcDRasDav",
                                 "categoryOptionCombos" => [
                                   { "name" => "15y+", "id" => "tMwM3ZBd7BN" },
                                   { "name" => "0-11m", "id" => "sqGRzCziswD" },
                                   { "name" => "12-59m", "id" => "wHBMVthqIX4" },
                                   { "name" => "5-14y", "id" => "b7fjZVL3q9b" }
                                 ] } }
          ] }.to_json)

        post :update, params: {
          project_id: project.id,
          id:         project.activities.first.id,
          activity: { name: "demo" },
          "state-mapping-action" =>   "data_element_coc",
          data_element_cocs: ["P3jJH5Tu5VC"]
        }

        expect(activity_state_added.name).to eq("Acute Flaccid Paralysis (AFP) follow-up - 5-14y")
        expect(activity_state_added.external_reference).to eq("P3jJH5Tu5VC.b7fjZVL3q9b")
        expect(activity_state_added.id).to be_nil
      end

      it "should add data elements to activity states" do
        stub_data_compound
        post :update, params: {
          project_id: project.id,
          id:         project.activities.first.id,
          activity: { name: "demo" },
          "state-mapping-action" =>   "data_element",
          data_elements: ["deid"]
        }
        expect_last_state_added("deid", "de name from dhis2")
      end

      it "should add indicators to activity states" do
        stub_data_compound
        post :update, params: {
          project_id: project.id,
          id:         project.activities.first.id,
          activity: { name: "demo" },
          "state-mapping-action" =>   "indicator",
          indicators: ["indicatorid"]
        }
        expect_last_state_added("indicatorid", "indicator name from dhis2")
      end

      def activity_state_added
        assigns[:activity].activity_states.last
      end

      def expect_last_state_added(external_reference, name)
        expect(activity_state_added.name).to eq(name)
        expect(activity_state_added.external_reference).to eq(external_reference)
        expect(activity_state_added.id).to be_nil
      end

      def stub_data_compound
        stub_request(:get, "http://play.dhis2.org/demo/api/dataElements?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}")
          .to_return(status: 200, body: {
            dataElements: [{
              id:   "deid",
              name: "de name from dhis2"
            }]
          }.to_json)
        stub_request(:get, "http://play.dhis2.org/demo/api/dataElementGroups?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}").to_return(status: 200, body: {
          dataElementGroups: []
        }.to_json)
        stub_request(:get, "http://play.dhis2.org/demo/api/indicators?fields=:all&pageSize=#{Dhis2SnapshotWorker::PAGE_SIZE}").to_return(status: 200, body: {
          indicators: [{
            id:   "indicatorid",
            name: "indicator name from dhis2"
          }]
        }.to_json)
      end
    end

    describe "#create" do
      it "should validate before creating" do
        expect do
          post :create, params: {
            project_id: project.id,
            activity:   {
              name:                       "",
              activity_states_attributes: [
                {
                  name:               "activity_state_name",
                  external_reference: "",
                  kind:               "data_element",
                  formula:            "1"
                }
              ]
            }
          }
        end.to_not change {
                     {
                       activity:        Activity.count,
                       activity_states: ActivityState.count
                     }
                   }
      end

      it "should be possible to create 2 activity constant" do
        expect do
          post :create, params: {
            project_id: project.id,
            activity:   {
              name:                       "activity_name",
              activity_states_attributes: [
                {
                  name:               "activity_state_name",
                  external_reference: "",
                  kind:               "formula",
                  formula:            "1",
                  state_id:           state_id_1
                },
                {
                  name:               "activity_state_name",
                  external_reference: "",
                  kind:               "formula",
                  formula:            "1",
                  state_id:           state_id_2
                }
              ]
            }
          }
        end.to change {
                 {
                   activity:        Activity.count,
                   activity_states: ActivityState.count
                 }
               }.from(activity: 2, activity_states: 4)
          .to(activity: 3, activity_states: 6)
      end

      it "should be possible to create a data element activity with a code" do
        expect do
          create_activity_with_code_and_data_element
        end.to change {
          {
            activity:        Activity.count,
            activity_states: ActivityState.count
          }
        }.from(activity: 2, activity_states: 4)
          .to(activity: 3, activity_states: 5)
        created_activity = Activity.all.last
        expect(created_activity.code).to eq("activity_code")
      end

      it "should prevent duplicate activity_code in same project" do
        create_activity_with_code_and_data_element
        create_activity_with_code_and_data_element
        expect(flash[:failure]).to eq("Some validation errors occured")
        expect(assigns(:activity).errors.full_messages).to eq(["Code has already been taken"])
      end

      it "should be possible to create a indicator activity state" do
        expect do
          post :create, params: {
            project_id: project.id,
            activity:   {
              name:                       "activity_name",
              activity_states_attributes: [
                {
                  name:               "activity_state_name",
                  external_reference: "external_reference",
                  kind:               "indicator",
                  state_id:           state_id_1
                }
              ]
            }
          }
        end.to change {
                 {
                   activity:        Activity.count,
                   activity_states: ActivityState.count
                 }
               }.from(activity: 2, activity_states: 4)
          .to(activity: 3, activity_states: 5)
      end

      def create_activity_with_code_and_data_element
        post :create, params: {
          project_id: project.id,
          activity:   {
            name:                       "activity_name",
            code:                       "activity_code",
            activity_states_attributes: [
              {
                name:               "activity_state_name",
                external_reference: "external_reference",
                kind:               "data_element",
                state_id:           state_id_1
              }
            ]
          }
        }
      end
    end
  end
end
