class CreateAdvertisers < ActiveRecord::Migration[8.0]
  def change
    create_table :advertisers do |t|
      t.integer :customer_id
      t.integer :platform_id
      t.string :platform_advertiser_id
      t.string :name

      t.timestamps
    end
  end
end
