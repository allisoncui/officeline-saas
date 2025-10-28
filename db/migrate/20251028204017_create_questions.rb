class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.references :office_hour, null: false, foreign_key: true
      t.text :question_text

      t.timestamps
    end
  end
end
