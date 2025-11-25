class AddQueueSessionToQueueEntries < ActiveRecord::Migration[7.1]
  def change
    add_reference :queue_entries, :queue_session, foreign_key: true
  end
end