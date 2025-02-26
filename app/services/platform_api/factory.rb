module PlatformApi
  class Factory
    def self.get_platform(platform_name)
      case platform_name
      when "megaphone"
        PlatformApi::MegaphonePlatformApi.new
      else
        raise "Unknown platform: #{platform_name}"
      end
    end
  end
end
