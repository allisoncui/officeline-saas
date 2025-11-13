Feature: calendar view of office hours
  As a student
  So that I can see office hours in a visual calendar format
  I want to toggle between list and calendar views

  Background: I am logged in as a student
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name                    | instructor            | day       | start_time | end_time | location          | ta_uni |
      | Engineering SaaS               | Junfeng Yang          | Tuesday   | 3:00PM     | 5:00PM   | Zoom              | yj123  |
      | Advanced Programming           | Jae Woo Lee           | Monday    | 1:00PM     | 3:00PM   | Pupin 301         | jl123  |
      | Data Structures                | Paul Blaer            | Wednesday | 2:00PM     | 4:00PM   | Lehman 301        | pb123  |
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    Then I should be on the office hours home page

  Scenario: toggle to calendar view
    Then I should see office hours in list format
    When I check the calendar toggle
    Then I should see the calendar view
    And I should see "Engineering SaaS"
    And I should see "Advanced Programming"
    And I should see "Data Structures"

  Scenario: toggle back to list view
    When I check the calendar toggle
    Then I should see the calendar view
    When I uncheck the calendar toggle
    Then I should see office hours in list format
    And I should see "Engineering SaaS"
    And I should see "Advanced Programming"

