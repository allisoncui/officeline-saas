class CreateQueueSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_sessions do |t|
      t.references :office_hour, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    
    add_index :queue_sessions, :started_at
  end
end