class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_accessor :email

  # Use uni + role combination for uniqueness
  validates :uni, presence: true
  validates :role, presence: true, inclusion: { in: %w[student ta] }
  validates :uni, uniqueness: { scope: :role, message: "already has a %{value} account" }
  validates :course_name, presence: true, if: -> { role == 'ta' }
  
  has_many :enrollments, dependent: :destroy
  has_many :saved_office_hours, through: :enrollments, source: :office_hour
  has_many :questions, dependent: :destroy
  has_many :queue_entries, dependent: :destroy
  
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
  
  # Serialize saved_classes as an array of course names
  serialize :saved_classes, coder: JSON, type: Array
  
  # Helper methods for saved classes
  def saved_class?(course_name)
    saved_classes.include?(course_name)
  end
  
  def add_saved_class(course_name)
    self.saved_classes = (saved_classes + [course_name]).uniq
    save
  end
  
  def remove_saved_class(course_name)
    self.saved_classes = saved_classes - [course_name]
    save
  end
  
  def saved_class_office_hours
    OfficeHour.where(course_name: saved_classes)
  end
  
  # Class methods for dual accounts
  def self.accounts_for_uni(uni)
    where(uni: uni)
  end
  
  def self.available_roles_for_uni(uni)
    existing_roles = where(uni: uni).pluck(:role)
    %w[student ta] - existing_roles
  end
  
  def self.has_both_accounts?(uni)
    where(uni: uni).pluck(:role).sort == %w[student ta]
  end
  
  # Instance method to get the other account for this UNI
  def other_account
    User.find_by(uni: uni, role: (ta? ? 'student' : 'ta'))
  end
end