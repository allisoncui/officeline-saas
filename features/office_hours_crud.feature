Feature: manage office hours
  As an administrator
  So that I can manage office hour schedules
  I want to create, view, update, and delete office hours

  Background: I am on the office hours home page
    Given I am on the office hours home page

  Scenario: create a new office hour
    When I follow "New office hour"
    Then I should be on the new office hour page
    When I fill in "Course name" with "Computer Science 101"
    And I fill in "Instructor" with "Dr. Smith"
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
      | course_name | instructor | day      | start_time | end_time | location |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Math 101"
    Then I should be on the office hour detail page
    And I should see "Math 101"
    And I should see "Dr. Jones"
    And I should see "Tuesday"
    And I should see "2:00PM"
    And I should see "4:00PM"
    And I should see "Room 201"

  Scenario: update an existing office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Physics 201"
    And I follow "Edit this office hour"
    Then I should be on the edit office hour page
    When I fill in "Instructor" with "Dr. Green"
    And I fill in "Location" with "Room 402"
    And I press "Update Office hour"
    Then I should be on the office hour detail page
    And I should see "Dr. Green"
    And I should see "Room 402"
    And I should see "Physics 201"

  Scenario: delete an office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location |
      | Chemistry   | Dr. White | Thursday | 9:00AM     | 11:00AM  | Room 501 |
    When I am on the office hours home page
    And I follow "Show this office hour" for "Chemistry"
    And I press "Destroy this office hour"
    Then I should be on the office hours home page
    And I should not see "Chemistry"
    And I should not see "Dr. White"

