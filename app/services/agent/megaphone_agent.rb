require 'net/http'
require 'uri'
require 'json'

module Agent
  class MegaphoneAgent < BaseAgent
    MEGAPHONE_BASE_URL = 'https://cms.megaphone.fm/api'

    def initialize(agent_name)
      @agent_name = agent_name
      @headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV['MEGAPHONE_TOKEN']}"
      }
    end
  
    def get_campaign(campaign_id)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV['MEGAPHONE_ORGANIZATION_ID']}/campaigns/#{campaign_id}")
      request = Net::HTTP::Get.new(uri, @headers)

      response = send_request(uri, request)
      convert_to_campaign_response_dto(response)
    end

    def create_campaign(data)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV['MEGAPHONE_ORGANIZATION_ID']}/campaigns")
      request = Net::HTTP::Post.new(uri, @headers)
      request.body = {
        title: data["title"],
        advertiserId: data["advertiser_id"],
        totalBudgetCents: (data["budget"].to_f * 100).to_i, # Convert to cents
        totalBudgetCurrency: data["currency"]
      }.to_json
  
      response = send_request(uri, request)
      convert_to_campaign_response_dto(response)
    end

    def update_campaign(campaign_id, data)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Put.new(uri, @headers)
      request.body = {
        :title => data["title"],
        :advertiserId => data["advertiser_id"],
        :totalBudgetCents => data["budget"],
        :totalBudgetCurrency => data["currency"],
      }.to_json
  
      response = send_request(uri, request)
      convert_to_campaign_response_dto(response)
    end

    def delete_campaign(campaign_id)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Delete.new(uri, @headers)
  
      response = send_request(uri, request)

      response.is_a?(Net::HTTPSuccess)
    end

    private

    def send_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        Rails.logger.info "[MegaphoneAgent] Request. uri: #{uri}, request: #{request.body}"
        response = http.request(request)
        Rails.logger.info "[MegaphoneAgent] Response: #{response.code} - #{response.body}"
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
