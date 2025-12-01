class OfficeHour < ApplicationRecord
  validates :course_name, :instructor, :day, :start_time, :end_time, :location, presence: true
  validates :ta_uni, presence: true, if: -> { instructor.present? }
  
  has_many :questions, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user
  has_many :queue_entries, dependent: :destroy
  has_many :queued_users, through: :queue_entries, source: :user
  has_many :queue_sessions, dependent: :destroy

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
    # Create a new queue session
    new_session = queue_sessions.create!(started_at: Time.current)
    
    questions.where(queue_session_id: nil).update_all(queue_session_id: new_session.id)
    
    update!(queue_active: true, queue_started_at: Time.current)
  end

  def close_queue!
    # End the current session
    current_session = queue_sessions.find_by(ended_at: nil)
    current_session&.update!(ended_at: Time.current)
    
    update!(queue_active: false)
    # Remove all waiting entries when queue closes
    queue_entries.where(status: 'waiting').update_all(status: 'removed')
  end

  def current_session
    queue_sessions.find_by(ended_at: nil)
  end

  def recent_sessions(limit: 10)
    queue_sessions.order(started_at: :desc).limit(limit)
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
  
  # Analytics methods
  def most_recent_session
    # Find the most recent queue session
    # A session is defined by a queue_started_at timestamp
    return nil unless queue_entries.any?
    
    # Get the most recent queue_started_at time
    recent_start = queue_entries.maximum(:created_at)
    return nil unless recent_start
    
    # Find all entries from the most recent session (within last 24 hours for safety)
    cutoff_time = 24.hours.ago
    most_recent_start = queue_entries.where('created_at >= ?', cutoff_time)
                                     .maximum(:created_at)
    
    return nil unless most_recent_start
    
    # Consider all entries created within 4 hours of the most recent entry as part of the same session
    session_window = most_recent_start - 4.hours
    
    {
      started_at: queue_started_at || most_recent_start,
      entries: queue_entries.where('created_at >= ? AND created_at <= ?', session_window, most_recent_start)
    }
  end
  
  def session_analytics
    session = most_recent_session
    return nil unless session
    
    entries = session[:entries]
    students_served = entries.where(status: 'served').count
    total_students = entries.count
    students_waiting = entries.where(status: 'waiting').count
    students_removed = entries.where(status: 'removed').count
    
    # Calculate session duration
    started_at = session[:started_at]
    # If queue is still active, use current time, otherwise use the last entry's update time
    ended_at = queue_active? ? Time.current : (entries.maximum(:updated_at) || started_at)
    duration_minutes = ((ended_at - started_at) / 60).round
    
    {
      started_at: started_at,
      ended_at: ended_at,
      duration_minutes: duration_minutes,
      students_served: students_served,
      total_students: total_students,
      students_waiting: students_waiting,
      students_removed: students_removed,
      service_rate: total_students > 0 ? (students_served.to_f / total_students * 100).round(1) : 0,
      still_active: queue_active?
    }
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