class CampaignSyncWorker
  include Sidekiq::Worker

  def perform
    platforms = Rails.application.config.platforms.keys

    Platform.where(name: platforms).each do |platform|
      # Get all campaigns from platform's api
      platform_api = PlatformApi::Factory.get_platform(platform.name)

      page = 1
      per_page = 100

      loop do
        Rails.logger.info("[CampaignSyncWorker] Platform #{platform.name}, Fetch page: #{page}, per_page: #{per_page}")
        result = platform_api.campaign_api.campaigns(page: page, per_page: per_page)
        platform_campaigns = result[:campaigns]

        break if platform_campaigns.empty?

        sync(platform, platform_campaigns)

        pagination = result[:pagination]
        total_pages = (pagination[:total] / per_page.to_f).ceil

        break if page >= total_pages
        page += 1
      end
    end
  end

  private

  def sync(platform, platform_campaigns)
    platform_campaign_ids = platform_campaigns.map { |campaign| campaign["id"] }

    existing_campaigns = Campaign.where(
      customer_id: ENV["CUSTOMER_ID"],
      platform_id: platform.id,
      platform_campaign_id: platform_campaign_ids
    )
    existing_platform_campaign_ids = existing_campaigns.pluck(:platform_campaign_id)
    missing_ids = platform_campaign_ids - existing_platform_campaign_ids

    # create
    missing_campaigns = platform_campaigns.select { |campaign| missing_ids.include? campaign["id"] }
                                          .map do |campaign|
                                            {
                                              customer_id: ENV["CUSTOMER_ID"],
                                              platform_id: platform.id,
                                              platform_campaign_id: campaign["id"],
                                              title: campaign["title"],
                                              currency: campaign["totalBudgetCurrency"],
                                              budget_cents: campaign["totalBudgetCents"].to_s,
                                              advertiser_id: campaign["advertiserId"]
                                            }
                                          end
    Campaign.insert_all!(missing_campaigns)
    Rails.logger.info "[CampaignSyncWorker] Platform #{platform.name}, Create missing data: #{missing_campaigns.length}"

    # update
    existing_campaigns_by_platform_campaign_id = existing_campaigns.each_with_object({}) { |campaign, hash| hash[campaign.platform_campaign_id] = campaign }
    new_platform_campaigns = platform_campaigns.select { |platform_campaign|
      campaign = existing_campaigns_by_platform_campaign_id[platform_campaign["id"]]
      next true if platform_campaign["title"] != campaign.title
      next true if platform_campaign["totalBudgetCurrency"] != campaign.currency
      next true if platform_campaign["totalBudgetCents"] != campaign.budget_cents
      next true if platform_campaign["advertiserId"] != campaign.advertiser_id
      false
    }.map { |campaign|
      {
        customer_id: ENV["CUSTOMER_ID"],
        platform_id: platform.id,
        platform_campaign_id: campaign["id"],
        title: campaign["title"],
        currency: campaign["totalBudgetCurrency"],
        budget_cents: campaign["totalBudgetCents"],
        advertiser_id: campaign["advertiserId"]
      }
    }

    # @todo update new_platform_campaigns to database
    Campaign.upsert_all(new_platform_campaigns)
    Rails.logger.info "[CampaignSyncWorker] Platform #{platform.name}, Update outdated data: #{new_platform_campaigns.length}"
  end
end
