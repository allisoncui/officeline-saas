FactoryBot.define do
  factory :office_hour do
    course_name { "Engineering SaaS" }
    instructor { "Junfeng Yang" }
    day { "Tuesday" }
    start_time { "3:00PM" }
    end_time { "5:00PM" }
    location { "Zoom" }
  end
end
