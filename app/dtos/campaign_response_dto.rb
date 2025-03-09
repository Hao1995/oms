class CampaignResponseDto
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :title, :string
  attribute :advertiser_id, :string
  attribute :budget_cents, :integer
  attribute :currency, :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  def self.from_response(response_data)
    new(
      id: response_data["id"],
      title: response_data["title"],
      advertiser_id: response_data["advertiserId"],
      budget_cents: response_data["totalBudgetCents"],
      currency: response_data["totalBudgetCurrency"],
      created_at: response_data["createdAt"],
      updated_at: response_data["updatedAt"]
    )
  end
end
