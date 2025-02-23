class CampaignsController < ApplicationController
  include Paginatable

  before_action :set_platform, :set_platform_api
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]

  CUSTOMER_ID = 123

  def index
    per_page = params.fetch(:per_page, 10).to_i
    page = params.fetch(:page, 1).to_i
    @campaigns = Campaign.page(page).per(per_page)
  end

  def show
    if @campaign.nil?
      redirect_to campaigns_url, alert: 'Campaign not found.'
    end
  end

  def new
    @campaign = Campaign.new
  end

  def edit
  end

  def create
    platform_campaign_dto = @platform_api.create_campaign(campaign_params)
    @campaign = Campaign.new(campaign_params.merge({
      platform_id: @platform.id,
      platform_campaign_id: platform_campaign_dto.id
    }))

    if @campaign.save
      redirect_to platform_campaign_path(@platform, @campaign), notice: 'Campaign was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    platform_campaign_dto = @platform_api.get_campaign(@campaign.platform_campaign_id)
    same = are_campaigns_same?(@campaign, platform_campaign_dto)

    if same || (!same && platform_campaign_dto.updated_at < @campaign.updated_at)
      Rails.logger.info "PUT /campaigns/:id. platform data is old, updating platform"
      @platform_api.update_campaign(@campaign.platform_campaign_id, campaign_params)
      @campaign.update!(campaign_params)
    else
      Rails.logger.info "PUT /campaigns/:id. platform data is new, syncing from platform's campaign data"
      @campaign.update!(
        title: platform_campaign_dto.title,
        advertiser_id: platform_campaign_dto.advertiser_id,
        budget_cents: platform_campaign_dto.budget_cents.to_s,
        currency: platform_campaign_dto.currency
      )
    end

    redirect_to @campaign, notice: 'Campaign was successfully updated.'
  rescue
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @platform_api.delete_campaign(@campaign.platform_campaign_id)
    @campaign.destroy
    redirect_to campaigns_url, notice: 'Campaign was successfully destroyed.'
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
    redirect_to campaigns_url, alert: 'Campaign not found.' unless @campaign
  end

  def campaign_params
    params.require(:campaign).permit(:platform_id, :platform_campaign_id, :title, :currency, :budget_cents, :advertiser_id)
          .merge(customer_id: CUSTOMER_ID)
  end

  def are_campaigns_same?(origin_campaign, platform_campaign_dto)
    platform_campaign_dto.title == origin_campaign.title &&
    platform_campaign_dto.advertiser_id == origin_campaign.advertiser_id &&
    platform_campaign_dto.budget_cents == origin_campaign.budget_cents &&
    platform_campaign_dto.currency == origin_campaign.currency
  end
end
