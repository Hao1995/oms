require "sidekiq"
require "sidekiq-cron"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  config.on(:startup) do
    # Initial data at the begging
    Rails.logger.debug "[Sidekiq] Run initial jobs: AdvertiserSyncWorker and CampaignSyncWorker"
    AdvertiserSyncWorker.perform_sync
    CampaignSyncWorker.perform_sync
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
