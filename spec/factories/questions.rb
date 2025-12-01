FactoryBot.define do
  factory :question do
    association :office_hour
    association :user
    question_text { "How do I implement authentication in Rails?" }
    question_type { "general" }
  end
end
