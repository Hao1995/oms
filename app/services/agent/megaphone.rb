require 'net/http'
require 'uri'
require 'json'

module Agent
  class Megaphone
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
        return nil
      end

      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Delete.new(uri, @headers)
  
      send_request(uri, request)
    end

    private
  
    def send_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        response = http.request(request)
        Rails.logger.info "[MegaphoneAgent] Response: #{response.code} - #{response.body}"
        response
      end
    end
  end
end
