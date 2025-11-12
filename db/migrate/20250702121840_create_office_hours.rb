class CreateOfficeHours < ActiveRecord::Migration[7.1]
  def change
    create_table :office_hours do |t|
      t.string 'course_name'
      t.string 'instructor'
      t.string 'day'
      t.string 'start_time'
      t.string 'end_time'
      t.string 'location'
      t.timestamps
    end
  end
end