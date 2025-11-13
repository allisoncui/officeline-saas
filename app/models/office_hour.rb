class OfficeHour < ApplicationRecord
  validates :course_name, :instructor, :day, :start_time, :end_time, :location, presence: true
  validates :ta_uni, presence: true, if: -> { instructor.present? }
  
  has_many :questions, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user
  has_many :queue_entries, dependent: :destroy
  has_many :queued_users, through: :queue_entries, source: :user

  # Define day order for sorting
  DAY_ORDER = {
    'Monday' => 1,
    'Tuesday' => 2,
    'Wednesday' => 3,
    'Thursday' => 4,
    'Friday' => 5,
    'Saturday' => 6,
    'Sunday' => 7
  }

  def self.all_days
    %w[Monday Tuesday Wednesday Thursday Friday]
  end

  def self.with_filters(days, sort_by)
    scope = days.nil? ? all : where(day: days.map(&:capitalize))
    
    case sort_by
    when 'day'
      scope.sort_by { |oh| [DAY_ORDER[oh.day] || 999, parse_time(oh.start_time)] }
    else
      scope.order(sort_by)
    end
  end
  
  # Queue methods
  def start_queue!
    update!(queue_active: true, queue_started_at: Time.current)
  end
  
  def close_queue!
    update!(queue_active: false)
    # Remove all waiting entries when queue closes
    queue_entries.where(status: 'waiting').update_all(status: 'removed')
  end
  
  def active_queue
    queue_entries.active
  end
  
  def queue_size
    active_queue.count
  end
  
  def user_in_queue?(user)
    queue_entries.exists?(user: user, status: 'waiting')
  end
  
  def user_queue_position(user)
    entry = queue_entries.find_by(user: user, status: 'waiting')
    entry&.position
  end

  private

  def self.parse_time(time_string)
    return 0 if time_string.blank?
    
    time_string = time_string.strip.upcase
    match = time_string.match(/(\d+):(\d+)(AM|PM)/)
    return 0 unless match
    
    hours = match[1].to_i
    minutes = match[2].to_i
    period = match[3]
    
    hours = 0 if hours == 12 && period == 'AM'
    hours += 12 if hours != 12 && period == 'PM'
    
    hours * 60 + minutes
  end
end