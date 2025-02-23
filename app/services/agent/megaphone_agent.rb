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
  
    def create_campaign(data)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV['MEGAPHONE_ORGANIZATION_ID']}/campaigns")
      request = Net::HTTP::Post.new(uri, @headers)
      request.body = {
        title: data["title"],
        advertiserId: data["advertiser_id"],
        totalBudgetCents: (data["budget"].to_f * 100).to_i, # Convert to cents
        totalBudgetCurrency: data["currency"]
      }.to_json
  
      send_request(uri, request)
    end

    def update_campaign(data)
      campaign_id = data.delete(:campaign_id)
      if campaign_id.nil?
        Rails.logger.error "[MegaphoneAgent] Missing campaign_id in update event"
        return nil
      end
  
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Put.new(uri, @headers)
      request.body = data.to_json
  
      send_request(uri, request)
    end

    def delete_campaign(campaign_id)
      if campaign_id.nil?
        Rails.logger.error "[MegaphoneAgent] Missing campaign_id in delete request"
        return false
      end

      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Delete.new(uri, @headers)
  
      response = send_request(uri, request)
      response.is_a?(Net::HTTPSuccess)
    end

    private

    def send_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        response = http.request(request)
        Rails.logger.info "[MegaphoneAgent] Response: #{response.code} - #{response.body}"

        unless response.code.to_i.in?([200, 201])
          if response.is_a?(Net::HTTPTooManyRequests) 
            raise Http::TooManyRequestsException.new(response.code, response&.body) 
          end
          raise Http::Exception.new(response.code, response&.body)
        end

        data = JSON.parse(response.body)
        CampaignResponseDto.new(
          id: data["id"],
          created_at: data["createdAt"],
          updated_at: data["updatedAt"],
          title: data["title"],
          advertiser_id: data["advertiserId"],
          budget_cents: data["totalBudgetCents"],
          currency: data["totalBudgetCurrency"]
        )
      end
    end
  end
end
