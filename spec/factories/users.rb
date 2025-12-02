FactoryBot.define do
  factory :user do
    sequence(:uni) { |n| "user#{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'student' }
    saved_classes { [] }
    
    # Add course_name for TAs
    course_name { role == 'ta' ? 'Computer Science 101' : nil }
    
    trait :student do
      role { 'student' }
      course_name { nil }
    end
    
    trait :ta do
      role { 'ta' }
      course_name { 'Computer Science 101' }
    end
  end
end