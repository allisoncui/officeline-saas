class OfficeHour < ApplicationRecord
  validates :course_name, :instructor, :day, :start_time, :end_time, :location, presence: true
  has_many :questions, dependent: :destroy

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
      # Sort by day order, then by start time within each day
      scope.sort_by { |oh| [DAY_ORDER[oh.day] || 999, parse_time(oh.start_time)] }
    else
      # For course_name, instructor, use database sorting
      scope.order(sort_by)
    end
  end

  private

  def self.parse_time(time_string)
    # Parse times like "3:00PM", "10:00AM" into comparable values
    return 0 if time_string.blank?
    
    time_string = time_string.strip.upcase
    match = time_string.match(/(\d+):(\d+)(AM|PM)/)
    return 0 unless match
    
    hours = match[1].to_i
    minutes = match[2].to_i
    period = match[3]
    
    # Convert to 24-hour format for comparison
    hours = 0 if hours == 12 && period == 'AM'
    hours += 12 if hours != 12 && period == 'PM'
    
    hours * 60 + minutes  # Return total minutes for easy comparison
  end
end