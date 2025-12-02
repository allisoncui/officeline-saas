Feature: manage office hours
  As an administrator
  So that I can manage office hour schedules
  I want to create, view, update, and delete office hours

  Background: I am logged in as a TA
    Given a TA user exists with UNI "ta123" and password "password123" and course "Computer Science 101"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should be on the office hours home page

  Scenario: create a new office hour
    When I follow "New office hour"
    Then I should be on the new office hour page
    When I fill in "Instructor" with "Dr. Smith"
    And I fill in "Day" with "Monday"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I press "Create Office hour"
    Then I should be on the office hour detail page
    And I should see "Computer Science 101"
    And I should see "Dr. Smith"
    And I should see "Monday"
    And I should see "10:00AM"
    And I should see "12:00PM"
    And I should see "Room 301"

  Scenario: view an existing office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Computer Science 101 | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | ta123  |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Computer Science 101"
    Then I should be on the office hour detail page
    And I should see "Computer Science 101"
    And I should see "Dr. Jones"
    And I should see "Tuesday"
    And I should see "2:00PM"
    And I should see "4:00PM"
    And I should see "Room 201"

  Scenario: update an existing office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Computer Science 101 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | ta123  |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Computer Science 101"
    And I follow "Edit Office Hour"
    Then I should be on the edit office hour page
    When I fill in "Instructor" with "Dr. Green"
    And I fill in "Location" with "Room 402"
    And I press "Update Office hour"
    Then I should be on the office hour detail page
    And I should see "Dr. Green"
    And I should see "Room 402"
    And I should see "Computer Science 101"

  Scenario: delete an office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Computer Science 101   | Dr. White  | Thursday | 9:00AM     | 11:00AM  | Room 501 | ta123  |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Computer Science 101"
    And I press "Delete"
    Then I should be on the office hours home page
    And I should not see "Computer Science 101"
    And I should not see "Dr. White"

