class CreateOfficeHours < ActiveRecord::Migration[7.1]
  def change
    create_table :office_hours do |t|
      t.string 'class'
      t.string 'instructor'
      t.string 'day'
      t.string 'start_time'
      t.string 'end_time'
      t.string 'location'
      # Add fields that let Rails automatically keep track
      # of when office hours are added or modified:
      t.timestamps
    end
  end
end