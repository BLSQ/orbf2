# frozen_string_literal: true

module Scorpio
  # rubocop:disable Naming/PredicateName
  # In this case, I think the `is_` actually provides some value
  #
  # Returns true if user is a developer or if we are in a development
  # environment.
  def self.is_developer?(user)
    return true if is_dev?
    return false unless user

    ENV.fetch("DEV_USER_IDS", "").split(",").include?(user.id.to_s)
  end

  # Development or QA environments will return true
  def self.is_dev?
    return true if Rails.env.development?
    return true if ENV["ORBF_STAGING"]

    false
  end
  # rubocop:enable Naming/PredicateName

  def self.can_impersonate?(user)
    is_developer?(user)
  end
end
