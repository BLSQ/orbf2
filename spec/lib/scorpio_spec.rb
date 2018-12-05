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
end
