# frozen_string_literal: true

# == Schema Information
#
# Table name: activities
#
#  id         :bigint(8)        not null, primary key
#  code       :string
#  name       :string           not null
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#  stable_id  :uuid             not null
#
# Indexes
#
#  index_activities_on_name_and_project_id  (name,project_id) UNIQUE
#  index_activities_on_project_id           (project_id)
#  index_activities_on_project_id_and_code  (project_id,code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

require "rails_helper"

RSpec.describe Activity, type: :model do
  include_context "basic_context"

  let!(:project) { full_project }
  let(:activity) do
    Activity.new(name:                       "activity_name",
                 code:                       "activity_code",
                 project:                    project,
                 activity_states_attributes: [
                   {
                     name:               "activity_state_name",
                     external_reference: "external_reference",
                     kind:               "data_element",
                     state_id:           project.states.first.id
                   }
                 ])
  end

  it "should be valid by default" do
    expect(activity.valid?).to be true
  end

  it "should allow blank code" do
    activity.code = ""
    expect(activity.valid?).to be true
  end

  it "should only contains lowercase letters and _ chars" do
    activity.code = "Activit4_Code"
    activity.valid?
    expect(activity.errors.full_messages).to eq(["Code : should only contains lowercase letters and _ like 'assisted_deliveries' or 'vaccination_under_one_year' vs #{activity.code}"])
    expect(activity.valid?).to be false
  end

  it "should allow getting data_element_id" do
    expect(activity.activity_states.first.data_element_id).to eq("external_reference")
  end

  describe "with activity states de_coc" do
    let(:activity_de_coc) do
      Activity.new(name:                       "activity_name",
                   code:                       "activity_code",
                   project:                    project,
                   activity_states_attributes: [
                     {
                       name:               "activity_state_name",
                       external_reference: "external_reference.coc_id",
                       kind:               "data_element_coc",
                       state_id:           project.states.first.id
                     }
                   ])
    end
    it "should allow getting data_element_id" do
      expect(activity_de_coc.activity_states.first.data_element_id).to eq("external_reference")
    end
  end

  describe "activity_state validations" do
    def assert_invalid(activity_states_attributes, expected_error)
      activity = Activity.new(name:                       "activity_name",
                              code:                       "activity_code",
                              project:                    project,
                              activity_states_attributes: [
                                activity_states_attributes.merge(
                                  name:     "activity_state_name",
                                  state_id: project.states.first.id
                                )
                              ])
      activity_state = activity.activity_states.first
      activity_state.valid?
      expect(activity_state.errors.messages).to eq(expected_error)
    end

    it "validates de.coc when data_element_with_coc: incorrect format" do
      assert_invalid(
        {
          external_reference: "dataelementid",
          kind:               "data_element_coc"
        },
        external_reference: ["should contains a dot like DATAELEMENTID.COCID"]
      )
    end

    it "validates de.coc when data_element_with_coc" do
      assert_invalid(
        {
          external_reference: "",
          kind:               "data_element_coc"
        },
        external_reference: ["can't be blank"]
      )
    end

    it "validates de when indicator : presence" do
      assert_invalid(
        {
          external_reference: "",
          kind:               "indicator"
        },
        external_reference: ["can't be blank"]
      )
    end
    it "validates de when indicator : wrong format" do
      assert_invalid(
        {
          external_reference: "de.coc",
          kind:               "indicator"
        },
        external_reference: ["should NOT contains a dot like DATAELEMENTID.COCID"]
      )
    end

    it "validates no dot when data_element : presence" do
      assert_invalid(
        {
          external_reference: "",
          kind:               "data_element"
        },
        external_reference: ["can't be blank"]
      )
    end

    it "validates no dot when data_element : wrong format" do
      assert_invalid(
        {
          external_reference: "de.coc",
          kind:               "data_element"
        },
        external_reference: ["should NOT contains a dot like DATAELEMENTID.COCID"]
      )
    end

    it "validates formula if formula kind : presence" do
      assert_invalid(
        {
          formula: "",
          kind:    "formula"
        },
        formula: ["can't be blank"]
      )
    end

    it "validates formula if formula kind : presence" do
      assert_invalid(
        {
          formula: nil,
          kind:    "formula"
        },
        formula: ["can't be blank"]
      )
    end
  end
end
