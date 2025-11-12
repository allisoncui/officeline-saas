class RemoveClassCodeFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :class_code, :string
  end
end
