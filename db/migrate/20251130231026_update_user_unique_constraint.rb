class UpdateUserUniqueConstraint < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :uni if index_exists?(:users, :uni)
    
    add_index :users, [:uni, :role], unique: true
  end
end
