require "net/http"
require "uri"
require "json"

module PlatformApi
  module Advertiser
    class Megaphone < Base
      include PlatformApi::Concerns::HttpClient

      BASE_URL = "https://cms.megaphone.fm/api/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/advertisers"

      def initialize(platform_name)
        @platform_name = platform_name
        @headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['MEGAPHONE_TOKEN']}"
        }
      end

      def list(page: 1, per_page: 100)
        uri = URI("#{BASE_URL}?page=#{page}&per_page=#{per_page}")
        request = Net::HTTP::Get.new(uri, @headers)

        response = send_request(uri, request)
        advertisers_data = JSON.parse(response.body)

        pagination = Common::PaginationDto.new(
          total: response["x-total"].to_i,
          per_page: response["x-per-page"].to_i,
          current_page: response["x-page"].to_i
        )

        ThirdParty::Advertisers::ListResponseDto.from_response(
          advertisers: advertisers_data,
          pagination: pagination
        )
      end
    end
  end
end
