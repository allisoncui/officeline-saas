class RemoveUniqueIndexFromQueueEntries < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique constraint
    remove_index :queue_entries, [:office_hour_id, :user_id], if_exists: true
    
    # Add a non-unique index for performance
    add_index :queue_entries, [:office_hour_id, :user_id], if_not_exists: true
  end
end