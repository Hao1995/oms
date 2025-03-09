module ThirdParty
  module Campaigns
    class ListResponseDto
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :campaigns, array: true, default: []
      attribute :pagination

      validates :campaigns, presence: true
      validates :pagination, presence: true

      def self.from_response(campaigns:, pagination:)
        new(
          campaigns: campaigns.map { |campaign| ResponseDto.from_response(campaign) },
          pagination: pagination
        )
      end
    end
  end
end
