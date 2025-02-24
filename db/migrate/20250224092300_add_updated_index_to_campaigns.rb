class AddUpdatedIndexToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_index :campaigns, :updated_at
  end
end
