
shared_context "basic_context" do
  let!(:user) do
    FactoryGirl.create(:user)
  end
  let!(:states) do
    states = [
      { name: "Claimed", configurable: false },
      { name: "Verified", configurable: false },
      { name: "Validated", configurable: false },
      { name: "Tarif", configurable: true },
      { name: "Max. Score", configurable: true },
      { name: "Budget", configurable: true }
    ]

    states.each do |state|
      state_record = State.find_or_create_by(name: state[:name])
      state_record.update_attributes(state)
    end
  end
end
