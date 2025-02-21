class AgentSyncOutbox < ApplicationRecord
  validates :event_type, inclusion: { in: %w[create_campaign update_campaign] }, presence: true
  validates :payload, presence: true
  validates :status, presence: false

  enum :event_type, {
    :create_campaign => "create_campaign",
    :update_campaign => "update_campaign",
  }
end