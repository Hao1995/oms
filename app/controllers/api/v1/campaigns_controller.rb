module Api
  module V1
    class CampaignsController < ApplicationController
      include Paginatable

      before_action :set_campaign, only: [:show, :update, :destroy]

      CUSTOMER_ID = 123  # the real customer_id should extract from login token, this just for simplify.
      AGENT = "megaphone" # Set default data for simplicity

      def initialize
        @agent = Agent::Factory.get_agent(AGENT)
      end

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
        agent_campaign_dto = @agent.create_campaign(campaign_params)
        @campaign = Campaign.new(campaign_params.merge({
          :agent => AGENT,
          :agent_campaign_id => agent_campaign_dto.id
        }))
        if @campaign.save
          render json: @campaign, status: :created
        else
          render json: @campaign.errors, status: :internal_server_error
        end
      end

      # PUT /campaigns/:id
      def update
        agent_campaign_dto = @agent.get_campaign(@campaign.agent_campaign_id)
        same = are_campaigns_same?(@campaign, agent_campaign_dto)

        if same || (!same && agent_campaign_dto.updated_at < @campaign.updated_at)
          Rails.logger.info "PUT /campaigns/:id. Update. Agent data is old, update to agent"
          agent.update_campaign(agentCampaign.agent_campaign_id, data)
          @campaign.update!(campaign_params)
        else
          Rails.logger.info "PUT /campaigns/:id. Update. Agent data is new, sync from agent's campaign data"

          origin_campaign.title  = agent_campaign_dto.title
          origin_campaign.advertiser_id  = agent_campaign_dto.advertiser_id
          origin_campaign.budget_cents  = agent_campaign_dto.budget_cents
          origin_campaign.currency = agent_campaign_dto.currency
          origin_campaign.save!
        end

        render json: @campaign
      rescue
        render json: @campaign.errors, status: :internal_server_error
      end

      # DELETE /campaigns/:id
      def destroy
        @agent.delete_campaign(@campaign.agent_campaign_id)
        @campaign.destroy
        head :no_content
      end

      private

      def set_campaign
        @campaign = Campaign.find_by(id: params[:id])
        render json: { error: 'Campaign not found' }, status: :not_found unless @campaign
      end

      def campaign_params
        params.permit(:title, :currency, :budget_cents, :advertiser_id)
              .merge(:customer_id => CUSTOMER_ID)
      end

      def are_campaigns_same?(origin_campaign, agent_campaign_dto)
        agent_campaign_dto.title == origin_campaign.title &&
        agent_campaign_dto.advertiser_id == origin_campaign.advertiser_id &&
        agent_campaign_dto.budget_cents == origin_campaign.budget &&
        agent_campaign_dto.currency == origin_campaign.currency
      end
    end
  end
end