class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Use uni instead of email for authentication
  validates :uni, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[student ta] }
  
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
end
