class AddQueueStatusToOfficeHours < ActiveRecord::Migration[7.1]
  def change
    add_column :office_hours, :queue_active, :boolean, default: false
    add_column :office_hours, :queue_started_at, :datetime
  end
end
