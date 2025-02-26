class ChangeAgentToPlatform < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :platform_id, :integer, after: :agent
    add_index :campaigns, [ :customer_id, :platform_id, :agent_campaign_id ], unique: true
    rename_column :campaigns, :agent_campaign_id, :platform_campaign_id
    remove_column :campaigns, :agent
  end
end
