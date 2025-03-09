module ThirdParty
  module Advertisers
    class ListResponseDto
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :advertisers, array: true
      attribute :pagination

      def self.from_response(advertisers:, pagination:)
        new(
          advertisers: advertisers.map { |advertiser| ResponseDto.from_response(advertiser) },
          pagination: pagination
        )
      end
    end
  end
end
