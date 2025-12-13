require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end
World(WithinHelpers)

When /^(.*) within (.*[^:])$/ do |step, parent|
  with_scope(parent) { When step }
end

When /^(.*) within (.*[^:]):$/ do |step, parent, table_or_string|
  with_scope(parent) { When "#{step}:", table_or_string }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^"]*)"$/ do |button|
  click_button(button)
end

When /^(?:|I )follow "([^"]*)"$/ do |link|
  if link == "Sign in" && current_path == new_user_session_path
  elsif link == "Sign Up" && current_path == new_user_registration_path
  elsif link == "New office hour"
    if page.has_link?("Add New Office Hour")
      click_link("Add New Office Hour")
    elsif page.has_link?("New office hour")
      click_link("New office hour")
    else
      visit new_office_hour_path
    end
  elsif link.casecmp("sign up").zero?
    if page.has_link?("Sign up")
      click_link("Sign up")
    else
      visit new_user_registration_path
    end  
  else
    click_link(link)
  end
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  if field == "Role"
    select(value, from: 'user_role')
    if value == "TA" || value == "ta"
      begin
        page.execute_script("toggleCourseNameField();")
      rescue Capybara::NotSupportedByDriverError
      end
    end
  elsif field == "Course Name"
    begin
      fill_in(field, :with => value, visible: true, wait: 2)
    rescue Capybara::ElementNotFound
      fill_in(field, :with => value, visible: :all)
    end
  else
    fill_in(field, :with => value)
  end
end

When /^(?:|I )fill in "([^"]*)" for "([^"]*)"$/ do |value, field|
  fill_in(field, :with => value)
end

When /^(?:|I )fill in the following:$/ do |fields|
  fields.rows_hash.each do |name, value|
    When %{I fill in "#{name}" with "#{value}"}
  end
end

When /^(?:|I )select "([^"]*)" from "([^"]*)"$/ do |value, field|
  select(value, :from => field)
end

When /^(?:|I )check (?:the\s+)?"([^"]*)"(?:\s*checkbox)?$/ do |field|
  check(field)
end

When /^(?:|I )uncheck (?:the\s+)?"([^"]*)"(?:\s*checkbox)?$/ do |field|
  uncheck(field)
end

When /^(?:|I )choose "([^"]*)"$/ do |field|
  choose(field)
end

When /^(?:|I )attach the file "([^"]*)" to "([^"]*)"$/ do |path, field|
  attach_file(field, File.expand_path(path))
end

Then /^(?:|I )should see "([^"]*)"$/ do |text|
  if text.match?(/invalid.*password|invalid.*uni/i)
    expect(page).to have_content(/#{Regexp.escape(text)}/i)
  else
    expect(page).to have_content(text)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  expect(page).to have_xpath('//*', :text => regexp)
end

Then /^(?:|I )should not see "([^"]*)"$/ do |text|
    expect(page).not_to have_content(text)
end

Then(/^I should not see office hour "(.*)"$/) do |course_name|
  within('#office_hours') do
    expect(page).not_to have_content(course_name)
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  expect(page).not_to have_xpath('//*', :text => regexp)
end

Then /^the "([^"]*)" field(?: within (.*))? should contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    expect(field_value).to match(/#{value}/)
  end
end

Then /^the "([^"]*)" field(?: within (.*))? should not contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    expect(field_value).not_to match(/#{value}/)
  end
end

Then /^the "([^"]*)" field should have the error "([^"]*)"$/ do |field, error_message|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')

  form_for_input = element.find(:xpath, 'ancestor::form[1]')
  using_formtastic = form_for_input[:class].include?('formtastic')
  error_class = using_formtastic ? 'error' : 'field_with_errors'

  expect(classes).to include(error_class)

  if using_formtastic
    error_paragraph = element.find(:xpath, '../*[@class="inline-errors"][1]')
    expect(error_paragraph).to have_content(error_message)
  else
    expect(page).to have_content(/#{Regexp.escape(field)}.*#{Regexp.escape(error_message)}|#{Regexp.escape(error_message)}.*#{Regexp.escape(field)}/i)
  end
end

Then /^the "([^"]*)" field should have no error$/ do |field|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')
  expect(classes).not_to include('field_with_errors')
  expect(classes).not_to include('error')
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    expect(field_checked).to be_truthy
  end
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should not be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    expect(field_checked).to be_falsy
  end
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  case page_name
  when /^the my classes page$/
    expect(current_path).to eq(student_profile_path)
  when /^the my questions page$/
    expect(current_path).to eq(student_questions_path)
  when /^the edit question page$/
    expect(current_path).to match(/\/office_hours\/\d+\/questions\/\d+\/edit$/)
  when /^the new office hour page$/
    expect(current_path).to eq(new_office_hour_path)
  when /^the office hour detail page$/
    expect(current_path).to match(/\/office_hours\/\d+$/)
  when /^the edit office hour page$/
    expect(current_path).to match(/\/office_hours\/\d+\/edit$/)
  else
    expect(current_path).to eq(path_to(page_name))
  end
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  query = URI.parse(current_url).query
  actual_params = query ? CGI.parse(query) : {}
  expected_params = {}
  expected_pairs.rows_hash.each_pair{|k,v| expected_params[k] = v.split(',')}

  expect(actual_params).to eq(expected_params)
end

Then /^show me the page$/ do
  save_and_open_page
end

Given(/^I sign in as "([^"]*)" with password "([^"]*)"$/) do |uni, password|
  visit root_path
  click_link "Sign in"
  fill_in "UNI", with: uni
  click_button "Continue"
  fill_in "Password", with: password
  click_button "Sign In"
end
