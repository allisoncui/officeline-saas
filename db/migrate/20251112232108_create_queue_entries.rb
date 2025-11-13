class CreateQueueEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_entries do |t|
      t.references :office_hour, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :position
      t.datetime :joined_at
      t.string :status, default: 'waiting'

      t.timestamps
    end
    
    add_index :queue_entries, [:office_hour_id, :user_id], unique: true
    add_index :queue_entries, [:office_hour_id, :status]
  end
end
