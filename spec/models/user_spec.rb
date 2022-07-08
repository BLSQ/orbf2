# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  dhis2_user_ref         :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  program_id             :integer
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_program_id            (program_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (program_id => programs.id)
#

require "rails_helper"

RSpec.describe User, type: :model do
  it "enables paper trail" do
    is_expected.to be_versioned
  end

  let(:user_in_program) { 
    program = FactoryBot.create(:program)
    FactoryBot.create(:user, program_id: program.id, dhis2_user_ref: "dhis2userref")
  }

  let(:user_without_program) { 
    FactoryBot.create(:user, dhis2_user_ref: "dhis2userref2")
  }

  let(:user_without_dhis2_user_ref) { 
    program = FactoryBot.create(:program)
    FactoryBot.create(:user, program_id: program.id)
  } 

  describe "enforcing uniqueness for dhis2_user_ref scoped by program_id" do
    it "should be valid if both dhis2_user_ref, program_id values are unique to a user" do
      expect(user_in_program).to be_valid
      expect(user_without_program).to be_valid
    end

    it "should be valid if new user has same dhis2_user_ref as another user in a different program" do
      new_user = FactoryBot.build(:user, program_id: FactoryBot.create(:program).id, dhis2_user_ref: user_in_program.dhis2_user_ref)
      expect(new_user).to be_valid
    end

    it "should be valid if new user is in same program as another user, both users lacking dhis2_user_refs" do
      new_user = FactoryBot.build(:user, program_id: user_without_dhis2_user_ref.program_id)
      expect(new_user).to be_valid
    end

    it "should not be valid if new user has same dhis2_user_ref as another user, both users lacking program_ids " do
      new_user = FactoryBot.build(:user, dhis2_user_ref: user_without_program.dhis2_user_ref)
      expect(new_user).to_not be_valid
    end

    it "should not be valid if new user has same dhis2_user_ref as another user in the same program" do
      new_user = FactoryBot.build(:user, program_id: user_in_program.program.id, dhis2_user_ref: user_in_program.dhis2_user_ref)
      expect(new_user).to_not be_valid
    end
  end 
end
