module Campaigns
  class UpdateReqDto
    attr_accessor :title, :advertiser_id, :budget_cents, :currency, :status, :platform_id, :platform_campaign_id

    def initialize(params)
      @platform_id = params[:platform_id]
      @platform_campaign_id = params[:platform_campaign_id]
      @title = params[:title]
      @currency = params[:currency]
      @budget_cents = params[:budget_cents]
      @status = params[:status]
      @advertiser_id = params[:advertiser_id]
    end

    def to_h
      {
        title: @title,
        advertiser_id: @advertiser_id,
        budget_cents: @budget_cents,
        currency: @currency,
        status: @status,
        platform_id: @platform_id,
        platform_campaign_id: @platform_campaign_id
      }.compact
    end
  end
end
