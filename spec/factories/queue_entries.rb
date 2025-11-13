FactoryBot.define do
  factory :queue_entry do
    office_hour { nil }
    user { nil }
    position { 1 }
    joined_at { "2025-11-12 18:21:08" }
    status { "MyString" }
  end
end
