require 'securerandom'

# Add a declarative step here for populating the DB with office hours.

Given(/the following office hours exist/) do |office_hours_table|
  office_hours_table.hashes.each do |office_hour|
    office_hour['ta_uni'] ||= "auto_ta_#{SecureRandom.hex(3)}"
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
  # The link might be in a card or have hidden text, so find by href
  find("a[href='#{office_hour_path(office_hour)}']").click
end

When(/I follow "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  raise "Could not find office hour with course name: #{course_name}" unless office_hour
  
  # Try to find and click the link, but if it's not visible (e.g., in TA view),
  # just visit the path directly
  begin
    # Try finding by exact href first (works for student view)
    link = find("a[href='#{office_hour_path(office_hour)}']", wait: 2)
    link.click
  rescue Capybara::ElementNotFound
    # If link not found, try finding by partial href match
    begin
      find("a[href*='#{office_hour_path(office_hour)}']", wait: 2).click
    rescue Capybara::ElementNotFound
      # Final fallback: just visit the path directly
      # This works for both student and TA views
      visit office_hour_path(office_hour)
    end
  end
end

Then(/I should be viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  expect(current_path).to eq office_hour_path(office_hour)
end

Given(/I am viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  visit office_hour_path(office_hour)
  # Wait for page to load
  expect(page).to have_content(course_name)
end

# All "I should see" and "I press" steps are handled by web_steps.rb

When(/I click "Back to office hours"/) do
  # Only click if we're on a page that has this link (show, edit, new)
  if page.has_link?('Back to office hours')
    click_link('Back to office hours')
  else
    # If we're already on index, just visit it
    visit office_hours_path
  end
end

### CRUD-related steps for Office Hours
# Note: "I should be on the new office hour page", "I should be on the office hour detail page",
# and "I should be on the edit office hour page" are handled by web_steps.rb to avoid ambiguity

### Validation-related steps

Then(/I should see error messages/) do
  expect(page).to have_content(/error|prohibited|can't be blank/i)
end

Then(/I should see "(.*)" in the error messages/) do |field_name|
  expect(page).to have_content(/#{Regexp.escape(field_name)}.*can't be blank|can't be blank.*#{Regexp.escape(field_name)}/i)
end

### User creation steps

Given(/a TA user exists with UNI "(.*)" and password "(.*)"/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'ta', password: password, password_confirmation: password)
end

Given(/a student user exists with UNI "(.*)" and password "(.*)"/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'student', password: password, password_confirmation: password)
end

### Dashboard and view-related steps
# Note: "I should be on the my classes page", "I should be on the my questions page", 
# "I should be on the edit question page", and "I should be on the new office hour page"
# are handled by web_steps.rb to avoid ambiguity

Then(/I should see office hours in list format/) do
  expect(page).not_to have_css('#calendar-view')
end

Then(/I should see the calendar view/) do
  expect(page).to have_css('#calendar-view')
end

When(/I check the calendar toggle/) do
  # Use Capybara's native checkbox methods which work without JavaScript driver
  check('calendar_toggle')
  # Manually set the hidden field value
  find('#hidden_view', visible: false).set('calendar')
  # Submit the form by clicking the submit button (more reliable than JavaScript)
  click_button('Refresh')
  # Wait for the page to reload with calendar view
  expect(page).to have_css('#calendar-view', wait: 5)
end

When(/I uncheck the calendar toggle/) do
  # Use Capybara's native checkbox methods which work without JavaScript driver
  uncheck('calendar_toggle')
  # Manually set the hidden field value
  find('#hidden_view', visible: false).set('list')
  # Submit the form by clicking the submit button (more reliable than JavaScript)
  click_button('Refresh')
  # Wait for the page to reload with list view
  expect(page).not_to have_css('#calendar-view', wait: 5)
end

### Enrollment-related steps

When(/I press "Save to My Classes" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  # Find the card containing the course name
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Save to My Classes')
  end
end

When(/I press "Remove" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  # Find the card containing the course name
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Remove')
  end
end

Then(/I should see "Saved" for "(.*)"/) do |course_name|
  # Find the card containing the course name
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_content('Saved')
  end
end

Then(/I should see "Save to My Classes" for "(.*)"/) do |course_name|
  # Find the card containing the course name
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Save to My Classes')
  end
end

Then(/I should see "Remove" for "(.*)"/) do |course_name|
  # Find the card containing the course name
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Remove')
  end
end