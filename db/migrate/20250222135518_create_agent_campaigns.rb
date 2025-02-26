class CreateAgentCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_campaigns, id: :integer do |t|
      t.integer :campaign_id, null: false
      t.column :agent, "ENUM('megaphone')", null: false
      t.string :agent_campaign_id, null: false
      t.datetime :created_at, comment: "from agent data"
      t.datetime :updated_at, comment: "from agent data"
    end

    add_index :agent_campaigns, [ :campaign_id, :agent, :agent_campaign_id ], unique: true, name: "uq_idx_campaign_agent"
  end
end
