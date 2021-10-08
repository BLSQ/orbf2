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

  # Calculates the db pool size needed, is used in the database.yml
  def self.db_pool_size
    sidekiq_concurrency = ENV.fetch("SIDEKIQ_CONCURRENCY", 1).to_i
    max_threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
    web_concurrency = ENV.fetch("WEB_CONCURRENCY", 1).to_i
    db_pool = ENV.fetch("DB_POOL", 1).to_i
    required_pool = [sidekiq_concurrency, max_threads * web_concurrency].max
    required_pool
  end
end
