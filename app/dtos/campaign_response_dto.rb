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
end
