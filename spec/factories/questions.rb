FactoryBot.define do
  factory :question do
    association :office_hour
    question_text { "How do I implement authentication in Rails?" }
  end
end
