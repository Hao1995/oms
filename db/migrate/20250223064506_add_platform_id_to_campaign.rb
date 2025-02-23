class AddPlatformIdToCampaign < ActiveRecord::Migration[8.0]
  def change
    platform = Platform.find_by(name: "megaphone")
    Campaign.where(platform_id: nil).update_all(platform_id: platform.id)
  end
end
