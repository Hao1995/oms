module PlatformApi
  module Advertiser
    class Base
      def list(page: 1, per_page: 100)
        raise NotImplementedError, "#{self.class} must implement 'list(page: 1, per_page: 100)'"
      end
    end
  end
end
