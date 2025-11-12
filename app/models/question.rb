class Question < ApplicationRecord
  belongs_to :office_hour
  belongs_to :user
  validates :question_text, presence: true
end
