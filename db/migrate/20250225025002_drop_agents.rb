class DropAgents < ActiveRecord::Migration[8.0]
  def change
    drop_table :agents_tables
  end
end
