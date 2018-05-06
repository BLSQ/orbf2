# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  project_id :integer          not null
#  stable_id  :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  code       :string
#

require "rails_helper"

RSpec.describe Activity, type: :model do
  include_context "basic_context"

  let!(:project) { full_project }
  let(:activity) do
    Activity.new(name:                       "activity_name",
                 code:                       "activity_code",
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
    expect(activity.valid?).to be false
    expect(activity.errors.full_messages).to eq(["Code : should only contains lowercase letters and _ like 'assisted_deliveries' or 'vaccination_under_one_year' vs #{activity.code}"])
  end
end
