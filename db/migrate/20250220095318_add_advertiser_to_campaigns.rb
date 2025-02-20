class AddAdvertiserToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :advertiser_id, :string, null: false, after: :budget
  end
end
