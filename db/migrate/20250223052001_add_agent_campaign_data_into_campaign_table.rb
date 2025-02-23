class AddAgentCampaignDataIntoCampaignTable < ActiveRecord::Migration[8.0]
  def change
    Campaign.destroy_all
    add_column :campaigns, :agent_campaign_id, :string, null: false, after: :customer_id
    add_column :campaigns, :agent, "ENUM('megaphone')", null: false, after: :customer_id
    rename_column :campaigns, :budget, :budget_cents
  end
end
