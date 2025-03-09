class CampaignUpdaterService
  def initialize(platform, campaign, platform_api, req_dto)
    @platform = platform
    @campaign = campaign
    @platform_api = platform_api
    @req_dto = req_dto
  end

  def action
    return handle_status_change_process if @campaign.status != @req_dto.status
    return handle_archive_process if @campaign.status == "archive"
    return handle_campaign_no_change_process if are_campaigns_same_content?(platform_campaign_dto)
    return sync_campaign_from_platform if platform_campaign_dto.updated_at > @campaign.updated_at
    sync_campaign_to_platform
  rescue => e
    Rails.logger.error "[CampaignUpdateService] Error: #{e.message}"
    Campaigns::UpdateRespDto.new(false, :alert, "Failed to update campaign.")
  end

  private

  def handle_status_change_process
    Rails.logger.debug "[CampaignUpdateService] handle status change process"
    update_data = @req_dto.to_h
    case @req_dto.status
    when "open"
      data = @req_dto.attributes.slice("title", "advertiser_id", "budget_cents", "currency")
      data["advertiser_id"] = Advertiser.select(:platform_advertiser_id)
                                        .find(data["advertiser_id"])
                                        .platform_advertiser_id
      platform_campaign_dto = @platform_api.campaign_api.create(data)
      update_data["platform_campaign_id"] = platform_campaign_dto.id
    when "archive"
      begin
        @platform_api.campaign_api.delete(@campaign.platform_campaign_id)
      rescue Http::NotFoundException => e
        Rails.logger.info "[CampaignUpdateService] Campaign not found on platform: #{e.message}"
      end
    else
      Rails.logger.warn "[CampaignUpdateService] invalid `status`"
      return Campaigns::UpdateRespDto.new(false, :alert, "Invalid `status`")
    end

    @campaign.update!(update_data)
    Campaigns::UpdateRespDto.new(true, :notice, "Update campaign successfully")
  end

  def handle_campaign_no_change_process
    Rails.logger.debug "[CampaignUpdateService] status: open, campaign no changes"
    Campaigns::UpdateRespDto.new(true, :notice, "Campaign no changes")
  end

  def sync_campaign_from_platform
    Rails.logger.debug "[CampaignUpdateService] platform data is new, sync the campaign from the platform"

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

    Campaigns::UpdateRespDto.new(true, :alert, "Cancel the update, due to data updates on the platform")
  end

  def sync_campaign_to_platform
    # case: difference campaigns - platform's campaign is old - open
    Rails.logger.debug "[CampaignUpdateService] platform data is old, update the campaign to the platform"

    data = @req_dto.to_h
    data["advertiser_id"] = Advertiser.select(:platform_advertiser_id)
                                      .find(data["advertiser_id"])
                                      .platform_advertiser_id
    @platform_api.campaign_api.update(@campaign.platform_campaign_id, data)

    Rails.logger.debug "[CampaignUpdateService] params: #{@req_dto.to_h}"
    @campaign.update!(@req_dto.to_h)

    Campaigns::UpdateRespDto.new(true, :notice, "Update the campaign successfully")
  end

  def handle_archive_process
    Rails.logger.debug "[CampaignUpdateService] case: campaign was archived, update to the database"
    @campaign.update!(@req_dto.to_h)
    Campaigns::UpdateRespDto.new(true, :notice, "Update the campaign successfully")
  end

  def platform_campaign_dto
    @platform_campaign_dto ||= @platform_api.campaign_api.get(@campaign.platform_campaign_id)
  end

  def are_campaigns_same_content?(platform_campaign_dto)
    platform_campaign_dto.title == @req_dto.title &&
    platform_campaign_dto.advertiser_id == @req_dto.advertiser_id &&
    platform_campaign_dto.budget_cents == @req_dto.budget_cents &&
    platform_campaign_dto.currency == @req_dto.currency
  end
end
