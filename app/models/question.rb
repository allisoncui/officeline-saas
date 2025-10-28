class Question < ApplicationRecord
  belongs_to :office_hour
  validates :question_text, presence: true
end
