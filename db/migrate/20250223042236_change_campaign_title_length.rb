class ChangeCampaignTitleLength < ActiveRecord::Migration[8.0]
  def change
    change_column :campaigns, :title, :string, null: false, limit: 255
  end
end
