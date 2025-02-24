module PlatformApi
  class MegaphonePlatformApi
    attr_reader :campaign_api, :advertiser_api

    def initialize
      @campaign_api = PlatformApi::Campaign::Megaphone.new("megaphone")
      @advertiser_api = PlatformApi::Advertiser::Megaphone.new("megaphone")
    end
  end
end
