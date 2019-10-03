require "rails_helper"

RSpec.describe Scorpio do
  describe '.is_dev?' do
    it 'returns true for development' do
      expect(Rails.env).to receive(:development?) { true }
      assert Scorpio.is_dev?, "Development is true"
    end

    it 'returns true for env variable' do
      expect(Rails.env).to receive(:development?) { false }
      ENV['ORBF_STAGING'] = "true"
      assert Scorpio.is_dev?, "Flag found so should be true"
      ENV.delete('ORBF_STAGING')
    end
  end

  describe '.is_developer?' do
    it 'returns true when in dev environment' do
      expect(Scorpio).to receive(:is_dev?) { true }

      expect(Scorpio.is_developer?(nil)).to eq(true)
    end

    it 'returns false if no user supplied' do
      expect(Scorpio).to receive(:is_dev?) { false }

      expect(Scorpio.is_developer?(nil)).to eq(false)
    end

    it 'returns true in production if user in env variable' do
      expect(Scorpio).to receive(:is_dev?) { false }

      ENV['DEV_USER_IDS'] = "1,2,3"
      fake_user = Struct.new(:id).new(3)
      expect(Scorpio.is_developer?(fake_user)).to eq(true)
    end

    it 'returns false in production if user not in env variable' do
      expect(Scorpio).to receive(:is_dev?) { false }

      ENV['DEV_USER_IDS'] = "1,2,3"
      fake_user = Struct.new(:id).new(5)
      expect(Scorpio.is_developer?(fake_user)).to eq(false)
    end
  end
end
