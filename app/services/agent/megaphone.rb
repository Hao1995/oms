require 'net/http'
require 'uri'
require 'json'

module Agent
  class Megaphone
    MEGAPHONE_BASE_URL = 'https://private-anon-17fe80dff5-megaphoneapi.apiary-mock.com'

    def initialize(agent_name)
      @agent_name = agent_name
    end
  
    def create_campaign(data)
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns")
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.body = data.to_json
  
      send_request(uri, request)
    end
  
    def update_campaign(data)
      campaign_id = data.delete('campaign_id')
      if campaign_id.nil?
        Rails.logger.error "[MegaphoneAgent] Missing campaign_id in update event"
        return nil
      end
  
      uri = URI("#{MEGAPHONE_BASE_URL}/organizations/#{ENV["MEGAPHONE_ORGANIZATION_ID"]}/campaigns/#{campaign_id}")
      request = Net::HTTP::Put.new(uri, 'Content-Type' => 'application/json')
      request.body = data.to_json
  
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