class OfficeHour < ApplicationRecord
  validates :course_name, :instructor, :day, :start_time, :end_time, :location, presence: true
  validates :ta_uni, presence: true, if: -> { instructor.present? }
  
  has_many :questions, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user
  has_many :queue_entries, dependent: :destroy
  has_many :queued_users, through: :queue_entries, source: :user
  has_many :queue_sessions, dependent: :destroy

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

  # Queue methods
  def start_queue!
    new_session = queue_sessions.create!(started_at: Time.current)
    questions.where(queue_session_id: nil).update_all(queue_session_id: new_session.id)
    update!(queue_active: true, queue_started_at: Time.current)
  end

  def soft_close_queue!
    # Close queue to new students but keep existing students in line
    update!(queue_active: false, queue_started_at: nil)
  end

  def hard_close_queue!
    # Close the current session
    current_session = queue_sessions.find_by(ended_at: nil)
    current_session&.update!(ended_at: Time.current)
    
    # Remove all waiting students from queue
    queue_entries.where(status: 'waiting').update_all(status: 'removed')
    
    # Mark queue as inactive
    update!(queue_active: false, queue_started_at: nil)
  end

  def close_queue!
    hard_close_queue!
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
end