class AddNameIndexToAdvertisers < ActiveRecord::Migration[8.0]
  def change
    add_index :advertisers, :name
  end
end
