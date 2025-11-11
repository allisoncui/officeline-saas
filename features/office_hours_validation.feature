Feature: validate office hours
  As an administrator
  So that I can ensure data quality
  I want to see validation errors when creating or updating office hours with invalid data

  Background: I am on the new office hour page
    Given I am on the office hours home page
    When I follow "New office hour"

  Scenario: create office hour with missing required fields
    When I press "Create Office hour"
    Then I should see error messages
    And I should see "Course name" in the error messages
    And I should see "Instructor" in the error messages
    And I should see "Day" in the error messages
    And I should see "Start time" in the error messages
    And I should see "End time" in the error messages
    And I should see "Location" in the error messages

  Scenario: create office hour with empty course name
    When I fill in "Instructor" with "Dr. Smith"
    And I fill in "Day" with "Monday"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I fill in "Course name" with ""
    And I press "Create Office hour"
    Then I should see error messages
    And I should see "Course name" in the error messages

  Scenario: create office hour with empty instructor
    When I fill in "Course name" with "Math 101"
    And I fill in "Day" with "Monday"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I fill in "Instructor" with ""
    And I press "Create Office hour"
    Then I should see error messages
    And I should see "Instructor" in the error messages

  Scenario: create office hour with empty day
    When I fill in "Course name" with "Math 101"
    And I fill in "Instructor" with "Dr. Smith"
    And I fill in "Start time" with "10:00AM"
    And I fill in "End time" with "12:00PM"
    And I fill in "Location" with "Room 301"
    And I fill in "Day" with ""
    And I press "Create Office hour"
    Then I should see error messages
    And I should see "Day" in the error messages

  Scenario: update office hour with invalid data
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Physics 201"
    And I follow "Edit this office hour"
    When I fill in "Course name" with ""
    And I press "Update Office hour"
    Then I should see error messages
    And I should see "Course name" in the error messages

