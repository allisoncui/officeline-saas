class Question < ApplicationRecord
  belongs_to :office_hour
  belongs_to :user
  belongs_to :queue_session, optional: true
  
  QUESTION_TYPES = [
    ['Homework Help', 'homework'],
    ['Concept Clarification', 'concept'],
    ['Project Help', 'project'],
    ['Exam Prep', 'exam'],
    ['General', 'general']
  ].freeze
  
  validates :question_text, presence: true
  validates :question_type, presence: true, inclusion: { in: QUESTION_TYPES.map { |_, value| value } }
  before_validation :set_default_question_type

  def question_type_display
    QUESTION_TYPES.find { |_, value| value == question_type }&.first || question_type&.humanize
  end
  
  private

  def set_default_question_type
    self.question_type = 'general' if question_type.blank?
  end
end
