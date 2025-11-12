class AddCourseNameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :course_name, :string
  end
end
