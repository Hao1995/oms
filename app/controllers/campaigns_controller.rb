class CampaignsController < ApplicationController
  include Paginatable

  before_action :set_platform_api
  before_action :set_campaign, only: [ :show, :edit, :update, :destroy ]
  before_action :set_advertisers, only: [ :new, :edit, :index ]

  def index
    campaigns = Campaign.includes(:advertiser)
                        .where(customer_id: ENV["CUSTOMER_ID"])
                        .where(platform_id: params[:platform_id])

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

    # Currency
    campaigns = campaigns.where(status: params[:status]) if params[:status].present?

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
    sort_column = params.fetch(:sort_by, "created_at")
    sort_direction = params.fetch(:sort_direction, "desc")

    if sort_column == "advertiser_name"
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
      redirect_to platform_campaign_path(@platform, @campaign), alert: "Campaign not found."
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

    redirect_to platform_campaign_path(@platform, @campaign), notice: "Campaign was successfully created." if @campaign.save
    redirect_to platform_campaigns_path(@platform), alert: "Failed to create campaign."
  end

  def update
    req_dto = Campaigns::UpdateReqDto.new(campaign_params)
    service = CampaignUpdaterService.new(@platform, @campaign, @platform_api, req_dto)
    resp_dto = service.action

    return redirect_to platform_campaign_path(@platform, @campaign), resp_dto.action => resp_dto.message if resp_dto.success
    redirect_to edit_platform_campaign_path(@platform, @campaign), resp_dto.action => resp_dto.message
  end

  def destroy
    @campaign.destroy
    @platform_api.campaign_api.delete(@campaign.platform_campaign_id)
    redirect_to platform_campaigns_path(@platform), notice: "Campaign was successfully destroyed."
  end

  private

  def platform
    @platform ||= Platform.find(params[:platform_id])
  end

  def set_platform_api
    @platform_api = PlatformApi::Factory.get_platform(platform.name)
  end

  def set_campaign
    @campaign = Campaign.where(customer_id: ENV["CUSTOMER_ID"])
                        .where(platform_id: params[:platform_id])
                        .find_by(id: params[:id])
  end

  def set_advertisers
    @advertisers = Advertiser.where(customer_id: ENV["CUSTOMER_ID"])
                            .where(platform_id: platform.id)
                            .order(name: :asc)
  end

  def campaign_params
    params.require(:campaign)
          .permit(
            :platform_id,
            :platform_campaign_id,
            :title,
            :currency,
            :budget_cents,
            :advertiser_id,
            :status
          ).merge(customer_id: ENV["CUSTOMER_ID"])
  end
end
