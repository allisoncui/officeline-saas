class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :office_hour

  validates :office_hour_id, uniqueness: { scope: :user_id }
end
