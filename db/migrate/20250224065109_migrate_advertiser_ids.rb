class MigrateAdvertiserIds < ActiveRecord::Migration[8.0]
  def change
    platforms = Rails.application.config.platforms.keys

    Platform.where(name: platforms).each do |platform|
      advertisersByPlatformID = Advertiser.all.each_with_object({}) do |advertiser, hash|
        hash[advertiser.platform_advertiser_id] = advertiser
      end

      Campaign.where(customer_id: ENV["CUSTOMER_ID"])
              .where(platform_id: platform.id)
              .each do |campaign|
                advertiser = advertisersByPlatformID[campaign.advertiser_id]
                unless advertiser
                  Rails.logger.debug "Campaign[#{campaign.id}]. Can not find advertiser by '#{campaign.advertiser_id}', destroy it."
                  campaign.destroy!
                else
                  campaign.advertiser_id = advertiser.id
                  campaign.save!
                  Rails.logger.debug "Campaign[#{campaign.id}]. Change '#{advertiser.platform_advertiser_id}' to '#{advertiser.id}'"
                end
              end
    end
  end
end
