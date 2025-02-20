class Campaign < ApplicationRecord
  validates :customer_id, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  validates :currency, inclusion: { in: %w[USD TWD] }
  validates :budget, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :advertiser_id, presence: true
end
  