FactoryBot.define do
  factory :enrollment do
    association :user
    association :office_hour
  end
end
