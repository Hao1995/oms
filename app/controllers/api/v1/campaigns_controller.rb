module Api
  module V1
    class CampaignsController < ApplicationController
      include Paginatable

      before_action :set_campaign, only: [:show, :update, :destroy]

      CUSTOMER_ID = 123

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
        @campaign = Campaign.new(campaign_params)
        if @campaign.save
          render json: @campaign, status: :created
        else
          render json: @campaign.errors, status: :internal_server_error
        end
      end

      # PUT /campaigns/:id
      def update
        if @campaign.update(campaign_params)
          render json: @campaign
        else
          render json: @campaign.errors, status: :internal_server_error
        end
      end

      # DELETE /campaigns/:id
      def destroy
        @campaign.destroy
        head :no_content
      end

      private

      def set_campaign
        @campaign = Campaign.find_by(id: params[:id])
        render json: { error: 'Campaign not found' }, status: :not_found unless @campaign
      end

      def campaign_params
        params.permit(:title, :currency, :budget, :advertiser_id)
              .merge(:customer_id => CUSTOMER_ID) # the real customer_id should extract from login token, this just for simplify.
      end
    end
  end
end