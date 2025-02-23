module PlatformApi
  class Factory
    def self.get_platform(platform_name)
      case platform_name
      when 'megaphone'
        PlatformApi::MegaphonePlatformApi.new(platform_name)
      else
        raise "Unknown platform: #{platform_name}"
      end
    end
  end
end
