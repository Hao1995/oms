require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

  config.on(:startup) do
    schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')

    if File.exist?(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Rails.application.config.after_initialize do
  # Init advertisers data at the beginning
  AdvertiserSyncWorker.perform_sync
end