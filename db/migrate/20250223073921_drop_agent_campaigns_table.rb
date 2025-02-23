class DropAgentCampaignsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :agent_campaigns
  end
end
