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
end
