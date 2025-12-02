Feature: save office hours to my classes
  As a student
  So that I can quickly access my enrolled classes
  I want to save office hours to my profile

  Background: I am logged in as a student
    Given a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should be on the office hours home page

  Scenario: save an office hour to my classes
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
    When I am on the office hours home page
    Then I should see "Save to My Classes" for "Math 101"
    When I press "Save to My Classes" for "Math 101"
    Then I should see "Office hour saved to your profile"
    And I should see "Saved" for "Math 101"

  Scenario: remove a saved office hour
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | tb123  |
    And I am on the office hours home page
    And I press "Save to My Classes" for "Physics 201"
    Then I should see "Remove" for "Physics 201"
    When I press "Remove" for "Physics 201"
    Then I should see "Office hour removed from your saved list"
    And I should see "Save to My Classes" for "Physics 201"

  Scenario: view my saved classes
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | tb123  |
    And I am on the office hours home page
    And I press "Save to My Classes" for "Math 101"
    And I follow "My Classes"
    Then I should be on the my classes page
    And I should see "My Saved Classes"
    And I should see "Math 101"
    And I should not see "Physics 201"