Feature: student dashboard
  As a student
  So that I can manage my academic resources
  I want to view my saved classes and submitted questions

  Background: I am logged in as a student
    Given a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    Then I should be on the office hours home page

  Scenario: view my saved classes
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | tb123  |
    And I am on the office hours home page
    And I press "Save Class" for "Math 101"
    And I follow "My Classes"
    Then I should be on the my classes page
    And I should see "My Saved Classes"
    And I should see "Math 101"
    And I should see "Dr. Jones"
    And I should not see "Physics 201"

  Scenario: filter and sort my saved classes
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
      | Physics 201 | Dr. Brown  | Wednesday| 1:00PM     | 3:00PM   | Room 401 | tb123  |
    And I am on the office hours home page
    And I press "Save Class" for "Math 101"
    And I press "Save Class" for "Physics 201"
    And I follow "My Classes"
    When I check the following days: Tuesday
    And I uncheck the following days: Wednesday, Thursday, Friday
    And I press "Refresh"
    Then I should see "Math 101"
    And I should not see "Physics 201"

  Scenario: view my submitted questions
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
    And I am on the office hours home page
    And I follow "Show this office hour" for "Math 101"
    When I fill in "question_question_text" with "How do I solve quadratic equations?"
    And I press "Submit Question"
    When I click "Back to Office Hours"
    And I follow "My Questions"
    Then I should be on the my questions page
    And I should see "My Submitted Questions"
    And I should see "Math 101"
    And I should see "How do I solve quadratic equations?"

  Scenario: view empty my classes page
    When I follow "My Classes"
    Then I should be on the my classes page
    And I should see "My Saved Classes"
    And I should see "You haven't saved any classes yet"

  Scenario: view empty my questions page
    When I follow "My Questions"
    Then I should be on the my questions page
    And I should see "My Submitted Questions"
    And I should see "You haven't submitted any questions yet"

