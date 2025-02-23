class CampaignResponseDto
  attr_accessor :id, :title, :advertiser_id, :budget_cents, :currency, :created_at, :updated_at

  def initialize(id:, title:, advertiser_id:, budget_cents:, currency:, created_at:, updated_at:)
    @id = id
    @title = title
    @advertiser_id = advertiser_id
    @budget_cents = budget_cents
    @currency = currency
    @created_at = created_at
    @updated_at = updated_at
  end
  
  def to_json
    {
      id: @id,
      title: @title,
      advertiser_id: @advertiser_id,
      budget_cents: @budget_cents,
      currency: @currency,
      created_at: @created_at,
      updated_at: @updated_at
    }.to_json
  end
end