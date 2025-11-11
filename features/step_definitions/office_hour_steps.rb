# Add a declarative step here for populating the DB with office hours.

Given(/the following office hours exist/) do |office_hours_table|
  office_hours_table.hashes.each do |office_hour|
    OfficeHour.create!(office_hour)
  end
end

Then(/(.*) seed office hours should exist/) do |n_seeds|
  expect(OfficeHour.count).to eq n_seeds.to_i
end

# Make sure that one string (regexp) occurs before or after another one
#   on the same page

Then(/^I should see "(.*)" before "(.*)"$/) do |e1, e2|
  # ensure that e1 occurs before e2 in the page body
  index1 = page.body.index(e1)
  index2 = page.body.index(e2)
  
  expect(index1).not_to be_nil, "Expected to find '#{e1}' on the page"
  expect(index2).not_to be_nil, "Expected to find '#{e2}' on the page"
  expect(index1).to be < index2, "Expected '#{e1}' to appear before '#{e2}'"
end

# Make it easier to express checking or unchecking several boxes at once
#  "When I check the following days: Monday, Tuesday"

When(/I check the following days: (.*)/) do |day_list|
  day_list.split(',').each do |day|
    check("days[#{day.strip}]")
  end
end

When(/I uncheck the following days: (.*)/) do |day_list|
  day_list.split(',').each do |day|
    uncheck("days[#{day.strip}]")
  end
end

Then(/^I should (not )?see the following office hours: (.*)$/) do |no, office_hour_list|
  office_hour_list.split(',').each do |office_hour|
    if no
      expect(page).not_to have_content(office_hour.strip)
    else
      expect(page).to have_content(office_hour.strip)
    end
  end
end

Then(/^I should see all of the office hours$/) do
  # Make sure that all the office hours in the app are visible
  OfficeHour.all.each do |office_hour|
    expect(page).to have_content(office_hour.course_name)
  end
end

### Utility Steps Just for this assignment.

Then(/^debug$/) do
  # Use this to write "Then debug" in your scenario to open a console.
  require "byebug"
  byebug
  1 # intentionally force debugger context in this method
end

Then(/^debug javascript$/) do
  # Use this to write "Then debug" in your scenario to open a JS console
  page.driver.debugger
  1
end

Then(/complete the rest of of this scenario/) do
  # This shows you what a basic cucumber scenario looks like.
  # You should leave this block inside office_hour_steps, but replace
  # the line in your scenarios with the appropriate steps.
  raise "Remove this step from your .feature files"
end

### Question-related steps

When(/I click "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  click_link "Show this office hour", href: office_hour_path(office_hour)
end

Then(/I should be viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  expect(current_path).to eq office_hour_path(office_hour)
end

Given(/I am viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  visit office_hour_path(office_hour)
end

When(/I click "Back to office hours"/) do
  click_link "Back to office hours"
end

### CRUD-related steps for Office Hours

When(/I follow "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  click_link "Show this office hour", href: office_hour_path(office_hour)
end

Then(/I should be on the new office hour page/) do
  expect(current_path).to eq new_office_hour_path
end

Then(/I should be on the office hour detail page/) do
  expect(current_path).to match(/\/office_hours\/\d+/)
end

Then(/I should be on the edit office hour page/) do
  expect(current_path).to match(/\/office_hours\/\d+\/edit/)
end

Then(/I should be on the office hours home page/) do
  expect(current_path).to eq office_hours_path
end

### Validation-related steps

Then(/I should see error messages/) do
  expect(page).to have_content(/error|prohibited|can't be blank/i)
end

Then(/I should see "(.*)" in the error messages/) do |field_name|
  expect(page).to have_content(/#{field_name}.*error|error.*#{field_name}/i)
end