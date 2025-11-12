class AddTaUniToOfficeHours < ActiveRecord::Migration[7.1]
  def change
    add_column :office_hours, :ta_uni, :string
  end
end
