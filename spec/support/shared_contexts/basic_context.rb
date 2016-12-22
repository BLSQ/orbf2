
shared_context "basic_context" do
  let!(:user) do
    FactoryGirl.create(:user)
  end
  let!(:states) do
    states = [
      { name: "Claimed" },
      { name: "Verified" },
      { name: "Validated" }
    ]

    states.map do |state_params|
      state = State.find_or_create_by!(state_params)
    end
  end
end
