
shared_context "basic_context" do
  let(:program) do
    create :program
  end
  let!(:user) do
    FactoryGirl.create(:user, program: program)
  end
end
