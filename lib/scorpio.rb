module Scorpio

  # Development or QA environemnts will return true
  def self.is_dev?
    Rails.env.development? || ENV['ORBF_STAGING']
  end
end
