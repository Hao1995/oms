class AgentCampaign < ApplicationRecord
  validates :campaign_id, presence: true
  validates :agent, inclusion: { in: %w[megaphone] }
  validates :agent_campaign_id, presence: true
end
