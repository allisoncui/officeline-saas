json.extract! office_hour, :id, :course_name, :instructor, :day, :start_time, :end_time, :location, :created_at, :updated_at
json.url office_hour_url(office_hour, format: :json)
