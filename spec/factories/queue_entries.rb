FactoryBot.define do
  factory :queue_entry do
    association :office_hour
    association :user
    position { 1 }
    joined_at { Time.current }
    status { "waiting" }
  end
end
