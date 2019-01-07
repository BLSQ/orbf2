# frozen_string_literal: true

module Scorpio
  # Development or QA environments will return true
  # rubocop:disable Naming/PredicateName
  # In this case, I think the `is_` actually provides some value
  def self.is_dev?
    Rails.env.development? || ENV["ORBF_STAGING"]
  end
  # rubocop:enable Naming/PredicateName
end
