require 'rails_helper'

RSpec.describe Project, type: :model do

  let!(:project) { create(:project) }

  it "should validate url " do
    expect(project.valid?).to eq true
    project.dhis2_url = "http:// bad : userexport@/dev:456.url"
    expect(project.valid?).to eq false
  end

end
