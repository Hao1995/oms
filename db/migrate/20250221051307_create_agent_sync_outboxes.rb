class CreateAgentSyncOutboxes < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_sync_outboxes, id: :integer, auto_increment: true  do |t|
      t.string :event_type
      t.json :payload
      t.boolean :status, default: false

      t.timestamps
    end
  end
end
