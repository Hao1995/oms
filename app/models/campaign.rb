class Campaign < ApplicationRecord
  validates :customer_id, presence: true
  validates :agent, inclusion: { in: %w[megaphone] }
  validates :agent_campaign_id, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :currency, inclusion: { in: %w[USD] }
  validates :budget_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :advertiser_id, presence: true
end
  