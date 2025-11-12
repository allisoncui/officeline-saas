class AddUserToQuestions < ActiveRecord::Migration[7.1]
  def up
    # First, add the column as nullable
    add_reference :questions, :user, null: true, foreign_key: true
    
    # Delete existing questions that don't have a user (or assign to a default user if needed)
    # For now, we'll just delete them since they're test data
    Question.where(user_id: nil).delete_all
    
    # Now make it not null
    change_column_null :questions, :user_id, false
  end
  
  def down
    remove_reference :questions, :user, foreign_key: true
  end
end
