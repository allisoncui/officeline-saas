class CreateEnrollments < ActiveRecord::Migration[7.1]
  def change
    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :office_hour, null: false, foreign_key: true

      t.timestamps
    end

    add_index :enrollments, [:user_id, :office_hour_id], unique: true
  end
end
