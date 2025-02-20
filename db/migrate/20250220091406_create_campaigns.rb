class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns, id: :integer, auto_increment: true do |t|
      t.integer :customer_id, null: false, comment: "for different customers"
      t.string :title, limit: 40, null: false
      t.column :currency, "ENUM('USD', 'TWD')", null: false
      t.decimal :budget, precision: 65, scale: 2, null: false
      t.timestamps null: false
    end
  end
end
