class QueueSession < ApplicationRecord
  belongs_to :office_hour
  has_many :queue_entries, dependent: :nullify
  
  validates :started_at, presence: true
  
  def duration_minutes
    return 0 unless started_at
    end_time = ended_at || Time.current
    ((end_time - started_at) / 60).round
  end
  
  def students_served
    queue_entries.where(status: 'served').count
  end
  
  def total_students
    queue_entries.count
  end
  
  def students_waiting
    queue_entries.where(status: 'waiting').count
  end
  
  def students_removed
    queue_entries.where(status: 'removed').count
  end
  
  def service_rate
    return 0 if total_students.zero?
    (students_served.to_f / total_students * 100).round(1)
  end
  
  def active?
    ended_at.nil?
  end
end