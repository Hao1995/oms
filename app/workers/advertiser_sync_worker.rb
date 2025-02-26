class AdvertiserSyncWorker
  include Sidekiq::Worker

  def perform
    platforms = Rails.application.config.platforms.keys

    Platform.where(name: platforms).each do |platform|
      # Get all advertiser from platform's api
      platform_api = PlatformApi::Factory.get_platform(platform.name)

      page = 1
      per_page = 100

      loop do
        Rails.logger.info("[AdvertiserSyncWorker] Platform #{platform.name}, Fetch page: #{page}, per_page: #{per_page}")
        result = platform_api.advertiser_api.list(page: page, per_page: per_page)
        platform_advertisers = result[:advertisers]

        break if platform_advertisers.empty?

        sync(platform, platform_advertisers)

        pagination = result[:pagination]
        total_pages = (pagination[:total] / per_page.to_f).ceil

        break if page >= total_pages
        page += 1
      end
    end
  end

  private

  def sync(platform, platform_advertisers)
    platform_advertiser_ids = platform_advertisers.map { |advertiser| advertiser["id"] }

    # upsert
    advertisers = platform_advertisers.map do |advertiser|
                                            {
                                              customer_id: ENV["CUSTOMER_ID"],
                                              platform_id: platform.id,
                                              platform_advertiser_id: advertiser["id"],
                                              name: advertiser["name"]
                                            }
                                          end
    Advertiser.upsert_all(advertisers)
    Rails.logger.info "[AdvertiserSyncWorker] Platform #{platform.name}, Upsert advertiser data: #{advertisers.length}"
  end
end
