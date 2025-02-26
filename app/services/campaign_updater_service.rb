class CampaignUpdaterService
  def initialize(platform, campaign, platform_api, req_dto)
    @platform = platform
    @campaign = campaign
    @platform_api = platform_api
    @req_dto = req_dto
    Rails.logger.debug "[CampaignsController] Update. req_dto: #{req_dto.to_h}"
  end

  def action
    if @campaign.status == "open"
      platform_campaign_dto = @platform_api.campaign_api.get(@campaign.platform_campaign_id)
      if are_campaigns_same_content?(platform_campaign_dto)
        Rails.logger.debug "[CampaignsController] Update. status: open, campaign no changes"
        return response(:success, :notice, "Campaign no changes")
      end
    end

    # status is changing
    if @campaign.status != @req_dto.status
      Rails.logger.debug "[CampaignsController] Update. status is changing."
      update_data = @req_dto.to_h
      case @req_dto.status
      when "open"
        data = @req_dto.to_h.slice(:title, :advertiser_id, :budget_cents, :currency)
        data[:advertiser_id] = Advertiser.select(:platform_advertiser_id)
                                          .find(data[:advertiser_id])
                                          .platform_advertiser_id
        platform_campaign_dto = @platform_api.campaign_api.create(data)
        update_data[:platform_campaign_id] = platform_campaign_dto.id
      when "archive"
        @platform_api.campaign_api.delete(@campaign.platform_campaign_id)
      else
        Rails.logger.warn "[CampaignsController] Update. invalid `status` parameter"
        return response(:failed, :alert, "Invalid `status` parameter")
      end

      @campaign.update!(update_data)
      return response(:success, :notice, "Update campaign successfully")
    end

    if @campaign.status == "open"
      if platform_campaign_dto.updated_at > @campaign.updated_at
        # case: difference campaigns - platform's campaign is new - open
        Rails.logger.debug "[CampaignsController] Update. platform data is new, syncing from platform's campaign data"

        advertiser_id = Advertiser.select(:id)
                                  .find_by(
                                    customer_id: ENV["CUSTOMER_ID"],
                                    platform_id: @platform.id,
                                    platform_advertiser_id: platform_campaign_dto.advertiser_id
                                  ).id

        @campaign.update!(
          title: platform_campaign_dto.title,
          advertiser_id: advertiser_id,
          budget_cents: platform_campaign_dto.budget_cents.to_s,
          currency: platform_campaign_dto.currency
        )

        return response(:success, :alert, "Cancel the update, due to data updates on the platform")
      else
        # case: difference campaigns - platform's campaign is old - open
        Rails.logger.debug "[CampaignsController] Update. platform data is old, updating platform"

        data = @req_dto.to_h
        data[:advertiser_id] = Advertiser.select(:platform_advertiser_id)
                                          .find(data[:advertiser_id])
                                          .platform_advertiser_id
        @platform_api.campaign_api.update(@campaign.platform_campaign_id, data)

        Rails.logger.debug "[CampaignsController] Update. params: #{@req_dto.to_h}"
        @campaign.update!(@req_dto.to_h)

        return response(:success, :notice, "Update the campaign successfully")
      end
    else
      Rails.logger.debug "[CampaignsController] Update. case: campaign was archived, update to the database"
      @campaign.update!(@req_dto.to_h)
      return response(:success, :notice, "Update the campaign successfully")
    end
  rescue => e
    Rails.logger.error "[CampaignsController] Update. Error: #{e.message}"
    return response(:failed, :alert, "Failed to update campaign.")
  end

  private

  def are_campaigns_same_content?(platform_campaign_dto)
    platform_campaign_dto.title == @req_dto.title &&
    platform_campaign_dto.advertiser_id == @req_dto.advertiser_id &&
    platform_campaign_dto.budget_cents == @req_dto.budget_cents &&
    platform_campaign_dto.currency == @req_dto.currency
  end

  def response(status, action, message)
    {
      status: status,
      action: action,
      message: message
    }
  end
end