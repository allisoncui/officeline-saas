class RemoveClassCodeFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :class_code, :string if column_exists?(:users, :class_code)
  end
end
