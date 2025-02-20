module Api
  module V1
    class CampaignsController < ApplicationController
      CUSTOMER_ID = 123
      def index
      end

      def show
      end

      def create
        @campaign = Campaign.new(campaign_params)
        if @campaign.save
          render json: @campaign, status: :created
        else
          render json: @campaign.errors, status: :internal_server_error
        end
      end

      def update
      end

      def destroy
      end

      private

      def campaign_params
        params.permit(:title, :currency, :budget, :advertiser_id)
              .merge(:customer_id => CUSTOMER_ID) # the real customer_id should extract from login token, this just for simplify.
      end
    end
  end
end