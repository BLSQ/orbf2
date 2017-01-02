
shared_context "basic_context" do
  let!(:user) do
    FactoryGirl.create(:user)
  end
  let!(:states) do
    states = [
      { name: "Claimed",    configurable: false,  level: "activity" },
      { name: "Verified",   configurable: false,  level: "activity" },
      { name: "Validated",  configurable: false,  level: "activity" },
      { name: "Max. Score", configurable: true,   level: "activity" },
      { name: "Tarif",      configurable: true,   level: "activity" },
      { name: "Budget",     configurable: true,   level: "package"  }
    ]

    states.each do |state|
      state_record = State.find_or_create_by(name: state[:name])
      state_record.update_attributes(state)
    end
  end
end
