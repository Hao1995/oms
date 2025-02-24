class AddFilterIndexesToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_index :campaigns, :title
    add_index :campaigns, :budget_cents
    add_index :campaigns, :currency
    add_index :campaigns, :advertiser_id
    add_index :campaigns, :created_at
  end
end
