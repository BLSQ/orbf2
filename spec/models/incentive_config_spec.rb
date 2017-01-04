
require "rails_helper"

RSpec.describe IncentiveConfig, type: :model do
  include_context "basic_context"

  describe "validations" do
    let(:incentives) do
      incentive_config = IncentiveConfig.new
      incentive_config.state = State.find_by(name: %w(Tarif))
      incentive_config.project = ProjectFactory.new.build(
        dhis2_url:  "https://play.dhis2.org/demo",
        user:       "admin",
        password:   "district",
        bypass_ssl: false
      )
      default_quantity_states = State.where(name: %w(Claimed Verified Tarif)).to_a
      incentive_config.package = incentive_config.project.packages[0]
      incentive_config.package.states << default_quantity_states
      incentive_config.start_date = "2016-01"
      incentive_config.end_date = "2016-03"
      incentive_config.entity_groups = "aze4564az"
      incentive_config
    end

    it "should validate states belong to project configurable states" do
      incentives.valid?
      expect(incentives.errors.full_messages).to eq []
    end

    it "should reject states belong to project configurable states" do
      incentives.state = State.find_by(name: %w(Budget))
      incentives.valid?
      expect(incentives.errors.full_messages).to eq ["State Budget is not associated to selected package. Quantity PMA has Tarif states"]
    end

    it "should reject when no entity groups specified" do
      incentives.entity_groups = nil
      incentives.valid?
      expect(incentives.errors.full_messages).to eq ["Entity groups You need to select at least one group"]
    end
  end
end
