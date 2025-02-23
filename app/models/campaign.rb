class Campaign < ApplicationRecord
  belongs_to :platform
  
  validates :customer_id, presence: true
  validates :platform_id, presence: true
  validates :platform_campaign_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :currency, presence: true
  validates :budget_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :advertiser_id, presence: true
end
  