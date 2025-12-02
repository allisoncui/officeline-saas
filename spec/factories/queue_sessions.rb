FactoryBot.define do
  factory :queue_session do
    association :office_hour
    started_at { Time.current }
    ended_at { Time.current }
  end
end
