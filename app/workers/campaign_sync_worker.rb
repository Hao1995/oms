class CampaignSyncWorker
  include Sidekiq::Worker
  include CampaignComparable

  def perform(*args)
    options = args.first
    page = 1
    per_page = 100
    unless options.nil?
      page = options[:page]
      per_page = options[:per_page]
    end

    platforms = Rails.application.config.platforms.keys

    Platform.where(name: platforms).each do |platform|
      platform_api = PlatformApi::Factory.get_platform(platform.name)

      loop do
        Rails.logger.info("[CampaignSyncWorker][#{platform.name}], Fetch page: #{page}, per_page: #{per_page}")
        result = platform_api.campaign_api.list(page: page, per_page: per_page)
        platform_campaigns = result.campaigns

        break if platform_campaigns.empty?

        sync(platform, platform_campaigns)

        break if page >= result.pagination.total_pages
        page += 1
      end
    end
  end

  private

  def sync(platform, platform_campaigns)
    platform_campaign_ids = platform_campaigns.map { |campaign| campaign.id }

    existing_campaigns = Campaign.where(
      customer_id: ENV["CUSTOMER_ID"],
      platform_id: platform.id,
      platform_campaign_id: platform_campaign_ids
    )
    existing_platform_campaign_ids = existing_campaigns.pluck(:platform_campaign_id)
    missing_ids = platform_campaign_ids - existing_platform_campaign_ids

    # create
    missing_campaigns = platform_campaigns.select { |campaign| missing_ids.include? campaign.id }
                                          .map do |campaign|
                                            {
                                              customer_id: ENV["CUSTOMER_ID"],
                                              platform_id: platform.id,
                                              platform_campaign_id: campaign.id,
                                              title: campaign.title,
                                              currency: campaign.currency,
                                              budget_cents: campaign.budget_cents.to_s,
                                              advertiser_id: campaign.advertiser_id
                                            }
                                          end
    Campaign.insert_all!(missing_campaigns)
    Rails.logger.info "[CampaignSyncWorker][#{platform.name}], Create missing data: #{missing_campaigns.length}"

    # update
    existing_campaigns_by_platform_campaign_id = existing_campaigns.each_with_object({}) { |campaign, hash| hash[campaign.platform_campaign_id] = campaign }
    new_platform_campaigns = platform_campaigns.select { |platform_campaign|
      campaign = existing_campaigns_by_platform_campaign_id[platform_campaign.id]
      !campaigns_attributes_match?(platform_campaign, campaign)
    }.map { |campaign|
      {
        customer_id: ENV["CUSTOMER_ID"],
        platform_id: platform.id,
        platform_campaign_id: campaign.id,
        title: campaign.title,
        currency: campaign.currency,
        budget_cents: campaign.budget_cents.to_s,
        advertiser_id: campaign.advertiser_id
      }
    }

    Campaign.upsert_all(new_platform_campaigns)
    Rails.logger.info "[CampaignSyncWorker][#{platform.name}], Update outdated data: #{new_platform_campaigns.length}"
  end
end
