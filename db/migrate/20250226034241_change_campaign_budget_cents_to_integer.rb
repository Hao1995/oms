class ChangeCampaignBudgetCentsToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :campaigns, :budget_cents, :integer, null: false
  end
end
