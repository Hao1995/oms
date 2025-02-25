class AddStatusToCamapaigns < ActiveRecord::Migration[8.0]
  def change
    execute <<-SQL
      ALTER TABLE campaigns
      ADD COLUMN `status` ENUM('open', 'archive') NOT NULL DEFAULT 'open' AFTER `advertiser_id`;
    SQL
  end
end
