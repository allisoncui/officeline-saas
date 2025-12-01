class AddQueueSessionToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_reference :questions, :queue_session, null: true, foreign_key: true
  end
end
