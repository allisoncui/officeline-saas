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
  expect(page.body.index(e1)).to be < page.body.index(e2)
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

Then(/^I should see office hours in chronological order by start time$/) do
  # This would need custom logic to verify time ordering
  # For now, just check that we see office hours
  expect(page).to have_css('#office_hours')
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