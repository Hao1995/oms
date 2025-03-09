class AdvertiserResponseDto
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
end
