Feature: validate office hours
  As an administrator
  So that I can ensure data quality
  I want to see validation errors when creating or updating office hours with invalid data

  Background: I am on the new office hour page
    Given a TA user exists with UNI "ta123" and password "password123" and course "Math 101"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should be on the office hours home page
    When I follow "New office hour"

  Scenario: create office hour with missing required fields
    When I press "Create Office hour"
    Then I should see error messages
    And I should see "Instructor" in the error messages
    And I should see "Day" in the error messages
    And I should see "Start time" in the error messages
    And I should see "End time" in the error messages
    And I should see "Location" in the error messages

  Scenario: create office hour with empty instructor
    When I fill in "Day" with "Monday"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I fill in "Instructor" with ""
    And I press "Create Office hour"
    Then I should see error messages
    And I should see "Instructor" in the error messages

  Scenario: create office hour with empty day
    When I fill in "Instructor" with "Dr. Smith"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I fill in "Day" with ""
    And I press "Create Office hour"
    Then I should see error messages
    And I should see "Day" in the error messages

  Scenario: update office hour with invalid data
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | ta123  |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Math 101"
    And I follow "Edit Office Hour"
    When I fill in "Instructor" with ""
    And I press "Update Office hour"
    Then I should see error messages
    And I should see "Instructor" in the error messages

