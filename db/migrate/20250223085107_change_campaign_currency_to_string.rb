class ChangeCampaignCurrencyToString < ActiveRecord::Migration[8.0]
  def change
    change_column :campaigns, :currency, :string, null: false, limit: 255
  end
end
