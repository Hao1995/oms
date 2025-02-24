class CampaignsController < ApplicationController
  include Paginatable

  before_action :set_platform, :set_platform_api
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]
  before_action :set_advertisers, only: [:new, :edit, :index]

  def index
    campaigns = Campaign.includes(:advertiser)

    # Title
    campaigns = campaigns.where("title LIKE ?", "#{params[:title]}%") if params[:title].present?

    # Advertiser ID
    campaigns = campaigns.where(advertiser_id: params[:advertiser_id]) if params[:advertiser_id].present?

    # Budget Cents
    if params[:budget_cents_min].present? && params[:budget_cents_max].present?
      campaigns = campaigns.where(budget_cents: params[:budget_cents_min]..params[:budget_cents_max])
    elsif params[:budget_cents_min].present?
      campaigns = campaigns.where("budget_cents >= ?", params[:budget_cents_min])
    elsif params[:budget_cents_max].present?
      campaigns = campaigns.where("budget_cents <= ?", params[:budget_cents_max])
    end

    # Currency
    campaigns = campaigns.where(currency: params[:currency]) if params[:currency].present?

    # Created At
    if params[:created_from].present? && params[:created_to].present?
      campaigns = campaigns.where(created_at: params[:created_from]..params[:created_to])
    elsif params[:created_from].present?
      campaigns = campaigns.where("created_at >= ?", params[:created_from])
    elsif params[:created_to].present?
      campaigns = campaigns.where("created_at <= ?", params[:created_to])
    end

    # Updated At
    if params[:updated_from].present? && params[:updated_to].present?
      campaigns = campaigns.where(updated_at: params[:updated_from]..params[:updated_to])
    elsif params[:updated_from].present?
      campaigns = campaigns.where("updated_at >= ?", params[:updated_from])
    elsif params[:updated_to].present?
      campaigns = campaigns.where("updated_at <= ?", params[:updated_to])
    end

    # Sorting
    sort_column = params.fetch(:sort_by, 'created_at')
    sort_direction = params.fetch(:sort_direction, 'desc')

    if sort_column == 'advertiser_name'
      campaigns = campaigns.joins(:advertiser)
      campaigns = campaigns.order("advertisers.name" => sort_direction)
    else
      campaigns = campaigns.order(sort_column => sort_direction)
    end

    # Pagination
    per_page = params.fetch(:per_page, 10).to_i
    page = params.fetch(:page, 1).to_i
    @campaigns = campaigns.page(page).per(per_page)
  end

  def show
    if @campaign.nil?
      redirect_to platform_campaign_path(@platform, @campaign), alert: 'Campaign not found.'
    end
  end

  def new
    @campaign = Campaign.new
  end

  def edit
  end

  def create
    advertiser = Advertiser.find_by(campaign_params[:advertiser_id])
    data = campaign_params
    data["advertiser_id"] = advertiser.platform_advertiser_id

    platform_campaign_dto = @platform_api.campaign_api.create(data)
    @campaign = Campaign.new(campaign_params.merge({
      platform_id: @platform.id,
      platform_campaign_id: platform_campaign_dto.id
    }))

    if @campaign.save
      redirect_to platform_campaign_path(@platform, @campaign), notice: 'Campaign was successfully created.'
    else
      redirect_to platform_campaigns_path(@platform), alert: 'Failed to create campaign.'
    end
  end

  def update
    platform_campaign_dto = @platform_api.campaign_api.get(@campaign.platform_campaign_id)
    same = are_campaigns_same?(@campaign, platform_campaign_dto)

    message = "Campaign not changes"
    unless same
      if platform_campaign_dto.updated_at > @campaign.updated_at
        Rails.logger.info "[CampaignsController] Update. platform data is new, syncing from platform's campaign data"

        advertiser = Advertiser.find_by(
          customer_id: ENV["CUSTOMER_ID"],
          platform_id: @platform.id,
          platform_advertiser_id: platform_campaign_dto.advertiser_id
        )

        @campaign.update!(
          title: platform_campaign_dto.title,
          advertiser_id: advertiser.id,
          budget_cents: platform_campaign_dto.budget_cents.to_s,
          currency: platform_campaign_dto.currency
        )

        message = "Cancel the update, due to data updates on the platform"
      else
        Rails.logger.info "[CampaignsController] Update. platform data is old, updating platform"

        advertiser = Advertiser.find_by(campaign_params[:advertiser_id])
        data = campaign_params
        data["advertiser_id"] = advertiser.platform_advertiser_id
        @platform_api.campaign_api.update(@campaign.platform_campaign_id, data)

        @campaign.update!(campaign_params)

        message = "Update the campaign successfully"
      end
    end
    redirect_to platform_campaign_path(@platform, @campaign), notice: message
  rescue => e
    Rails.logger.error "[CampaignsController] Update. Error: #{e.message}"
    redirect_to edit_platform_campaign_path(@platform, @campaign), alert: 'Failed to update campaign.'
  end

  def destroy
    @platform_api.campaign_api.delete(@campaign.platform_campaign_id)
    @campaign.destroy
    redirect_to platform_campaigns_path(@platform), notice: 'Campaign was successfully destroyed.'
  end

  private

  def set_platform
    @platform = Platform.find(params[:platform_id])
  end

  def set_platform_api
    @platform_api = PlatformApi::Factory.get_platform(@platform.name)
  end

  def set_campaign
    @campaign = Campaign.find_by(id: params[:id])
  end

  def set_advertisers
    @advertisers = Advertiser.where(customer_id: ENV["CUSTOMER_ID"])
                            .where(platform_id: @platform.id)
  end

  def campaign_params
    params.require(:campaign).permit(:platform_id, :platform_campaign_id, :title, :currency, :budget_cents, :advertiser_id)
          .merge(customer_id: ENV["CUSTOMER_ID"])
  end

  def are_campaigns_same?(origin_campaign, platform_campaign_dto)
    platform_campaign_dto.title == origin_campaign.title &&
    platform_campaign_dto.advertiser_id == origin_campaign.advertiser_id &&
    platform_campaign_dto.budget_cents == origin_campaign.budget_cents &&
    platform_campaign_dto.currency == origin_campaign.currency
  end
end
