require "sidekiq/throttled"
Sidekiq::Throttled.setup!

# The app could be provisioned with Redis cloud or with Heroku Redis,
# they use a different env variable, so check them both, and use the
# one that's there.
redis_url = ENV["REDISCLOUD_URL"] || ENV["REDIS_URL"]

if redis_url
  Sidekiq.configure_server do |config|
    config.redis = { url: redis_url }
    poolsize = ( ENV["SIDEKIQ_DB_POOL_SIZE"] || ENV["SIDEKIQ_CONCURRENCY"] || "10").to_i
    ActiveRecord::Base.configurations[Rails.env]["pool"] = poolsize
    ActiveRecord::Base.establish_connection
    puts "Sidekiq server : db pool size adapted to : #{ActiveRecord::Base.connection_pool.instance_eval { @size }} vs concurrency : #{config.options[:concurrency]}"
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: redis_url }
  end
end
