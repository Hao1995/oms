class Advertiser < ApplicationRecord
  belongs_to :platform

  validates :customer_id, presence: true
  validates :platform_id, presence: true
  validates :platform_advertiser_id, presence: true
  validates :name, presence: true
end
