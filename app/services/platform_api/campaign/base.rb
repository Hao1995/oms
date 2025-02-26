module PlatformApi
  module Campaign
    class Base
      def get(campaign_id)
        raise NotImplementedError, "#{self.class} must implement 'get(campaign_id)'"
      end

      def list(page: 1, per_page: 100)
        raise NotImplementedError, "#{self.class} must implement 'list(page: 1, per_page: 100)'"
      end

      def create(data)
        raise NotImplementedError, "#{self.class} must implement 'create(data)'"
      end

      def update(campaign_id, data)
        raise NotImplementedError, "#{self.class} must implement 'update(data)'"
      end

      def delete(campaign_id)
        raise NotImplementedError, "#{self.class} must implement 'delete(campaign_id)'"
      end
    end
  end
end
