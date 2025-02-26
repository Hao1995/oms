class AddUqIndexToAdvertisers < ActiveRecord::Migration[8.0]
  def change
    add_index :advertisers, [ :customer_id, :platform_id, :platform_advertiser_id ], unique: true
  end
end
