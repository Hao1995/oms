module ThirdParty
  module Advertisers
    class ResponseDto
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :id, :string
      attribute :name, :string
      attribute :agency_id, :string
      attribute :competitive_categories, :string
      attribute :created_at, :datetime
      attribute :updated_at, :datetime

      def self.from_response(response_data)
        new(
          id: response_data["id"],
          name: response_data["name"],
          agency_id: response_data["agencyId"],
          competitive_categories: response_data["competitiveCategories"],
          created_at: response_data["createdAt"],
          updated_at: response_data["updatedAt"]
        )
      end
    end
  end
end
