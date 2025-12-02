require 'securerandom'

Given(/the following office hours exist/) do |office_hours_table|
  office_hours_table.hashes.each do |office_hour|
    office_hour['ta_uni'] ||= "auto_ta_#{SecureRandom.hex(3)}"
    OfficeHour.create!(office_hour)
  end
end

Then(/(.*) seed office hours should exist/) do |n_seeds|
  expect(OfficeHour.count).to eq n_seeds.to_i
end

Then(/^I should see "(.*)" before "(.*)"$/) do |e1, e2|
  index1 = page.body.index(e1)
  index2 = page.body.index(e2)

  expect(index1).not_to be_nil
  expect(index2).not_to be_nil
  expect(index1).to be < index2
end

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
  OfficeHour.all.each do |office_hour|
    expect(page).to have_content(office_hour.course_name)
  end
end

Then(/^debug$/) do
  require "byebug"
  byebug
end

Then(/^debug javascript$/) do
  page.driver.debugger
end

When(/I click the office hour link for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  find("a[href='#{office_hour_path(office_hour)}']").click
end

When(/I follow "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  visit office_hour_path(office_hour)
end

Then(/I should be viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  expect(page).to have_current_path(office_hour_path(office_hour))
end

Given(/I am viewing the office hour details for course "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  visit office_hour_path(office_hour)
end

When(/I click "Back to Office Hours"/) do
  if page.has_link?("Back to Office Hours")
    click_link("Back to Office Hours")
  else
    visit office_hours_path
  end
end

Then(/I should see error messages/) do
  expect(page).to have_content(/can't be blank|prohibited/i)
end

Then(/I should see "(.*)" in the error messages/) do |field|
  expect(page).to have_content(/#{field}.*can't be blank/i)
end

Given(/a TA user exists with UNI "(.*)" and password "(.*)" and course "(.*)"/) do |uni, password, course_name|
  FactoryBot.create(:user, uni: uni, role: 'ta',
    password: password, password_confirmation: password,
    course_name: course_name)
end

Given(/^a TA user exists with UNI "([^"]*)" and password "([^"]*)"(?! and course)/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'ta',
    password: password, password_confirmation: password,
    course_name: 'Engineering SaaS')
end

Given(/a student user exists with UNI "(.*)" and password "(.*)"/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'student',
    password: password, password_confirmation: password)
end

Then(/I should see office hours in list format/) do
  expect(page).not_to have_css('#calendar-view')
end

Then(/I should see the calendar view/) do
  expect(page).to have_css('#calendar-view')
end

When(/I check the calendar toggle/) do
  check('calendar_toggle')
  find('#hidden_view', visible: false).set('calendar')
  click_button('Refresh')
end

When(/I uncheck the calendar toggle/) do
  uncheck('calendar_toggle')
  find('#hidden_view', visible: false).set('list')
  click_button('Refresh')
end

When(/I press "Save Class" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Save Class')
  end
end

When(/I press "Remove Class" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Remove Class')
  end
end

Then(/I should see "Saved" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{course_name}/)
  within(card) { expect(page).to have_content("Saved") }
end

Then(/I should see "Save Class" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Save Class')
  end
end

Then(/I should see "Remove Class" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Remove Class')
  end
end

Then("I am on the new office hour page") do
  expect(page).to have_current_path(new_office_hour_path)
end

Then("I am on the edit office hour page") do
  expect(page).to have_content("Editing office hour")
end

Then("I am on the office hour detail page") do
  expect(page.current_path).to match(/office_hours\/\d+/)
end

When("I press Start Queue")  { click_button("Start Queue") }
When("I press Close Queue")  { click_button("Close Queue") }
When("I press Join Queue")   { click_button("Join Queue") }
When("I press Leave Queue")  { click_button("Leave Queue") }

Given('I sign in as "{string}" with password "{string}"') do |uni, password|
  visit root_path
  click_link "Sign in"
  fill_in "UNI", with: uni
  click_button "Continue"
  fill_in "Password", with: password
  click_button "Sign In"
end

When('I sign in as "{string}" with password "{string}"') do |uni, password|
  visit root_path
  click_link "Sign in"
  fill_in "UNI", with: uni
  click_button "Continue"
  fill_in "Password", with: password
  click_button "Sign In"
end
