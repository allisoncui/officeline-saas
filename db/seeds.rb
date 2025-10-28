# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed the RottenPotatoes DB with some movies.
hours = [
  { course_name: 'Engineering SaaS', instructor: 'Junfeng Yang', day: 'Tuesday', start_time: '3:00PM', end_time: '5:00PM', location: 'Zoom' },
  { course_name: 'Advanced Programming', instructor: 'Jae Woo Lee', day: 'Monday', start_time: '1:00PM', end_time: '3:00PM', location: 'Pupin 301' },
  { course_name: 'Data Structures', instructor: 'Paul Blaer', day: 'Wednesday', start_time: '2:00PM', end_time: '4:00PM', location: 'Lehman 301' },
  { course_name: 'Data Structures', instructor: 'Paul Blaer', day: 'Thursday', start_time: '10:00AM', end_time: '12:00PM', location: 'IAB 417' },
  { course_name: 'Buddhism', instructor: 'Michael Como', day: 'Tuesday', start_time: '8:00AM', end_time: '10:00AM', location: 'Zoom' },
  { course_name: 'Art Humanities', instructor: 'Ioannis Mylonopoulos', day: 'Tuesday', start_time: '5:00PM', end_time: '7:00PM', location: 'Schermerhorn 608' },
  { course_name: 'Intermediate Macroeconomics', instructor: 'Irasema Alonso', day: 'Thursday', start_time: '1:00PM', end_time: '3:00PM', location: 'Uris 301' },
  { course_name: 'Natural Language Processing', instructor: 'Daniel Bauer', day: 'Wednesday', start_time: '2:00PM', end_time: '4:00PM', location: 'NOCO 501' },
  { course_name: 'Discrete Mathematics', instructor: 'Ansaf Salleb', day: 'Monday', start_time: '4:00PM', end_time: '6:00PM', location: 'Pupin 428' },
  { course_name: 'Linear Algebra', instructor: 'George Dragomir', day: 'Friday', start_time: '12:00PM', end_time: '2:00PM', location: 'Math 312' }
]

hours.each do |hour|
  OfficeHour.create!(hour)
end
