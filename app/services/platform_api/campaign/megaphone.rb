require 'net/http'
require 'uri'
require 'json'

module PlatformApi
  module Campaign
    class Megaphone < Base
      BASE_URL = "https://cms.megaphone.fm/api/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns"

      def initialize(platform_name)
        @platform_name = platform_name
        @headers = {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{ENV['MEGAPHONE_TOKEN']}"
        }
      end
    
      def get(campaign_id)
        uri = URI("#{BASE_URL}/#{campaign_id}")
        request = Net::HTTP::Get.new(uri, @headers)

        response = send_request(uri, request)
        convert_to_campaign_response_dto(response)
      end

      def list(page: 1, per_page: 100)
        uri = URI("#{BASE_URL}?page=#{page}&per_page=#{per_page}")
        request = Net::HTTP::Get.new(uri, @headers)

        response = send_request(uri, request)
        campaigns = JSON.parse(response.body)

        pagination_info = {
          total: response['x-total'].to_i,
          per_page: response['x-per-page'].to_i,
          current_page: response['x-page'].to_i
        }

        { campaigns: campaigns, pagination: pagination_info }
      end

      def create(data)
        uri = URI("#{BASE_URL}")
        request = Net::HTTP::Post.new(uri, @headers)
        request.body = {
          title: data["title"],
          advertiserId: data["advertiser_id"],
          totalBudgetCents: data["budget_cents"].to_i,
          totalBudgetCurrency: data["currency"]
        }.to_json
    
        response = send_request(uri, request)
        convert_to_campaign_response_dto(response)
      end

      def update(campaign_id, data)
        uri = URI("#{BASE_URL}/#{campaign_id}")
        request = Net::HTTP::Put.new(uri, @headers)
        request.body = {
          :title => data["title"],
          :advertiserId => data["advertiser_id"],
          :totalBudgetCents => data["budget_cents"],
          :totalBudgetCurrency => data["currency"],
        }.to_json
    
        response = send_request(uri, request)
        convert_to_campaign_response_dto(response)
      end

      def delete(campaign_id)
        uri = URI("#{BASE_URL}/#{campaign_id}")
        request = Net::HTTP::Delete.new(uri, @headers)
    
        response = send_request(uri, request)

        response.is_a?(Net::HTTPSuccess)
      end

      private

      def send_request(uri, request)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          Rails.logger.debug "[MegaphoneAgent] Request. uri: #{uri}, request: #{request.body}"
          response = http.request(request)
          Rails.logger.debug "[MegaphoneAgent] Response: #{response.code} - #{response.body}"
          response
        end
      end

      def convert_to_campaign_response_dto(response)
        unless response.code.to_i.in?([200, 201])
          if response.is_a?(Net::HTTPTooManyRequests)
            raise Http::TooManyRequestsException.new(response.code, response&.body)
          end
          raise Http::BaseException.new(response.code, response&.body)
        end

        data = JSON.parse(response.body)
        CampaignResponseDto.new(
          id: data["id"],
          title: data["title"],
          advertiser_id: data["advertiserId"],
          budget_cents: data["totalBudgetCents"],
          currency: data["totalBudgetCurrency"],
          created_at: data["createdAt"],
          updated_at: data["updatedAt"],
        )
      end
    end
  end
end
