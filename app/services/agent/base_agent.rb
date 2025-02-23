module Agent
  class Base
    def create_campaign(data)
      raise NotImplementedError, "#{self.class} must implement 'create_campaign(data)'"
    end

    def update_campaign(data)
      raise NotImplementedError, "#{self.class} must implement 'update_campaign(data)'"
    end

    def delete_campaign(campaign_id)
      raise NotImplementedError, "#{self.class} must implement 'delete_campaign(campaign_id)'"
    end
  end
end