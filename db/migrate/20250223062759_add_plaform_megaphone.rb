class AddPlaformMegaphone < ActiveRecord::Migration[8.0]
  def change
    Platform.create!({
      name: "megaphone"
    })
  end
end
