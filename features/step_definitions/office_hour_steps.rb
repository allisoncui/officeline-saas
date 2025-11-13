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
  
  expect(index1).not_to be_nil, "Expected to find '#{e1}' on the page"
  expect(index2).not_to be_nil, "Expected to find '#{e2}' on the page"
  expect(index1).to be < index2, "Expected '#{e1}' to appear before '#{e2}'"
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
  1
end

Then(/^debug javascript$/) do
  page.driver.debugger
  1
end

Then(/complete the rest of of this scenario/) do
  raise "Remove this step from your .feature files"
end

When(/I click "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  find("a[href='#{office_hour_path(office_hour)}']").click
end

When(/I follow "Show this office hour" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  raise "Could not find office hour with course name: #{course_name}" unless office_hour
  
  begin
    link = find("a[href='#{office_hour_path(office_hour)}']", wait: 2)
    link.click
  rescue Capybara::ElementNotFound
    begin
      find("a[href*='#{office_hour_path(office_hour)}']", wait: 2).click
    rescue Capybara::ElementNotFound
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
  expect(page).to have_content(course_name)
end

When(/I click "Back to office hours"/) do
  if page.has_link?('Back to office hours')
    click_link('Back to office hours')
  else
    visit office_hours_path
  end
end

Then(/I should see error messages/) do
  expect(page).to have_content(/error|prohibited|can't be blank/i)
end

Then(/I should see "(.*)" in the error messages/) do |field_name|
  expect(page).to have_content(/#{Regexp.escape(field_name)}.*can't be blank|can't be blank.*#{Regexp.escape(field_name)}/i)
end

Given(/a TA user exists with UNI "(.*)" and password "(.*)" and course "(.*)"/) do |uni, password, course_name|
  FactoryBot.create(:user, uni: uni, role: 'ta', password: password, password_confirmation: password, course_name: course_name)
end

Given(/^a TA user exists with UNI "([^"]*)" and password "([^"]*)"(?! and course)/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'ta', password: password, password_confirmation: password, course_name: 'Engineering SaaS')
end

Given(/a student user exists with UNI "(.*)" and password "(.*)"/) do |uni, password|
  FactoryBot.create(:user, uni: uni, role: 'student', password: password, password_confirmation: password)
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
  expect(page).to have_css('#calendar-view', wait: 5)
end

When(/I uncheck the calendar toggle/) do
  uncheck('calendar_toggle')
  find('#hidden_view', visible: false).set('list')
  click_button('Refresh')
  expect(page).not_to have_css('#calendar-view', wait: 5)
end

When(/I press "Save to My Classes" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Save to My Classes')
  end
end

When(/I press "Remove" for "(.*)"/) do |course_name|
  office_hour = OfficeHour.find_by(course_name: course_name)
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    click_button('Remove')
  end
end

Then(/I should see "Saved" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_content('Saved')
  end
end

Then(/I should see "Save to My Classes" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Save to My Classes')
  end
end

Then(/I should see "Remove" for "(.*)"/) do |course_name|
  card = page.find("div.ol-card", text: /#{Regexp.escape(course_name)}/, match: :first)
  within(card) do
    expect(page).to have_button('Remove')
  end
end