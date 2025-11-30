class AddSavedClassesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :saved_classes, :text, default: '[]'
  end
end
