class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_accessor :email

  # Use uni instead of email for authentication
  validates :uni, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[student ta] }
  
  has_many :enrollments, dependent: :destroy
  has_many :saved_office_hours, through: :enrollments, source: :office_hour
  
  # Override Devise's email requirement
  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end

  # Role helpers
  def ta?
    role.to_s.downcase == "ta"
  end

  def student?
    role.to_s.downcase == "student"
  end
  
  has_many :questions, dependent: :destroy
  has_many :queue_entries, dependent: :destroy
end
