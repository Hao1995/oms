class RemoveTwdFromCampaignCurrency < ActiveRecord::Migration[8.0]
  def change
    execute <<-SQL
      ALTER TABLE campaigns
      MODIFY COLUMN currency ENUM('USD') NOT NULL;
    SQL
  end
end
