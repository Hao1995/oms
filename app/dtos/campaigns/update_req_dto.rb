module Campaigns
  class UpdateReqDto
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :title, :string
    attribute :advertiser_id, :string
    attribute :budget_cents, :integer
    attribute :currency, :string
    attribute :status, :string
    attribute :platform_id, :integer
    attribute :platform_campaign_id, :string

    def to_h
      attributes.compact
    end
  end
end
