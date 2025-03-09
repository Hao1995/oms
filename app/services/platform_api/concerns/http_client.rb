module PlatformApi
  module Concerns
    module HttpClient
      extend ActiveSupport::Concern

      private

      def send_request(uri, request, success_codes: [ 200, 201, 204 ])
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          Rails.logger.debug "[#{self.class.name}] Request. method: #{request.method}, uri: #{uri}, request: #{request.body}"
          response = http.request(request)
          Rails.logger.debug "[#{self.class.name}] Response: #{response.code} - #{response.body}"
          response
        end

        unless response.code.to_i.in?(success_codes)
          if response.is_a?(Net::HTTPTooManyRequests)
            raise Http::TooManyRequestsException.new(response.code, response&.body)
          elsif response.is_a?(Net::HTTPNotFound)
            raise Http::NotFoundException.new(response.code, response&.body)
          else
            raise Http::BaseException.new(response.code, response&.body)
          end
        end

        response
      end
    end
  end
end
