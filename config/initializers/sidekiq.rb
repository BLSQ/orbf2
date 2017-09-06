require "sidekiq/throttled"
Sidekiq::Throttled.setup!

if ENV["REDISCLOUD_URL"]
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV["REDISCLOUD_URL"] }
    poolsize = ( ENV["SIDEKIQ_DB_POOL_SIZE"] || ENV["SIDEKIQ_CONCURRENCY"] || "10").to_i
    ActiveRecord::Base.configurations[Rails.env]["pool"] = poolsize
    ActiveRecord::Base.establish_connection
    puts "Sidekiq server : db pool size adapted to : #{ActiveRecord::Base.connection_pool.instance_eval { @size }} vs concurrency : #{config.options[:concurrency]}"
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV["REDISCLOUD_URL"] }
  end
end
