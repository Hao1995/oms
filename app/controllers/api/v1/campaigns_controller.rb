module Api
  module V1
    class CampaignsController < ApplicationController
      include Paginatable

      before_action :set_campaign, only: [:show, :update, :destroy]

      CUSTOMER_ID = 123  # the real customer_id should extract from login token, use const for simplify.
      PLATFORM_ID = 1  # the real platform_id should extract from login token, use const for simplify.

      # GET /campaigns
      def index
        per_page = params.fetch(:per_page, 10).to_i
        page = params.fetch(:page, 1).to_i
        @campaigns = Campaign.page(page).per(per_page)
        render json: paginate(@campaigns)
      end

      # GET /campaigns/:id
      def show
        render json: @campaign
      end

      # POST /campaigns
      def create
        platform = Platform.find(PLATFORM_ID)
        platform_api = PlatformApi::Factory.get_platform(platform.name)

        platform_campaign_dto = platform_api.create_campaign(campaign_params)
        @campaign = Campaign.new(campaign_params.merge({
          :platform_id => platform.id,
          :platform_campaign_id => platform_campaign_dto.id
        }))
        if @campaign.save
          render json: @campaign, status: :created
        else
          render json: @campaign.errors, status: :internal_server_error
        end
      end

      # PUT /campaigns/:id
      def update
        platform = Platform.find(PLATFORM_ID)
        platform_api = PlatformApi::Factory.get_platform(platform.name)

        platform_campaign_dto = platform_api.get_campaign(@campaign.platform_campaign_id)
        same = are_campaigns_same?(@campaign, platform_campaign_dto)

        if same || (!same && platform_campaign_dto.updated_at < @campaign.updated_at)
          Rails.logger.info "PUT /campaigns/:id. Update. platform data is old, update to platform"
          platform_api.update_campaign(@campaign.platform_campaign_id, campaign_params)
          @campaign.update!(campaign_params)
        else
          Rails.logger.info "PUT /campaigns/:id. Update. platform data is new, sync from platform's campaign data"
          @campaign.title  = platform_campaign_dto.title
          @campaign.advertiser_id  = platform_campaign_dto.advertiser_id
          @campaign.budget_cents  = platform_campaign_dto.budget_cents.to_s
          @campaign.currency = platform_campaign_dto.currency
          @campaign.save!
        end

        render json: @campaign
      rescue
        render json: @campaign.errors, status: :internal_server_error
      end

      # DELETE /campaigns/:id
      def destroy
        platform = Platform.find(PLATFORM_ID)
        platform_api = PlatformApi::Factory.get_platform(platform.name)

        platform_api.delete_campaign(@campaign.platform_campaign_id)
        @campaign.destroy
        head :no_content
      end

      private

      def set_campaign
        @campaign = Campaign.find_by(id: params[:id])
        render json: { error: 'Campaign not found' }, status: :not_found unless @campaign
      end

      def campaign_params
        params.permit(:platform_id, :platform_campaign_id, :title, :currency, :budget_cents, :advertiser_id)
              .merge(:customer_id => CUSTOMER_ID)
      end

      def platform
        @platform ||= Platform.find(PLATFORM_ID)
      end

      def platform_api
        @platform_api ||= PlatformApi::Factory.get_platform(platform.name)
      end

      def are_campaigns_same?(origin_campaign, platform_campaign_dto)
        platform_campaign_dto.title == origin_campaign.title &&
        platform_campaign_dto.advertiser_id == origin_campaign.advertiser_id &&
        platform_campaign_dto.budget_cents == origin_campaign.budget_cents &&
        platform_campaign_dto.currency == origin_campaign.currency
      end
    end
  end
end