module PlatformApi
  class BasePlatformApi
    def get_campaign(campaign_id)
      raise NotImplementedError, "#{self.class} must implement 'get_campaign(campaign_id)'"
    end

    def create_campaign(data)
      raise NotImplementedError, "#{self.class} must implement 'create_campaign(data)'"
    end

    def update_campaign(campaign_id, data)
      raise NotImplementedError, "#{self.class} must implement 'update_campaign(data)'"
    end

    def delete_campaign(campaign_id)
      raise NotImplementedError, "#{self.class} must implement 'delete_campaign(campaign_id)'"
    end
  end
end