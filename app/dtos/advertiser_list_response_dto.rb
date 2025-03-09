class AdvertiserListResponseDto
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :advertisers, array: true, default: []
  attribute :pagination

  validates :advertisers, presence: true
  validates :pagination, presence: true

  def self.from_response(advertisers:, pagination:)
    new(
      advertisers: advertisers.map { |advertiser| AdvertiserResponseDto.from_response(advertiser) },
      pagination: pagination
    )
  end
end
