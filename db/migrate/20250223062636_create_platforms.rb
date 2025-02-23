class CreatePlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :platforms, id: :integer, auto_increment: true do |t|
      t.string :name

      t.timestamps
    end
  end
end
