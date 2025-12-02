Feature: manage questions
  As a student
  So that I can update or remove my questions
  I want to edit and delete my submitted questions

  Background: I am logged in as a student with a question
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    And I follow "Show this office hour" for "Math 101"
    When I fill in "question_question_text" with "Original question text"
    And I press "Submit Question"

  Scenario: edit my question
    When I follow "Edit Question"
    Then I should be on the edit question page
    And I should see "Original question text"
    When I fill in "question_question_text" with "Updated question text"
    And I press "Update Question"
    Then I should be on the office hour detail page
    And I should see "Question updated successfully!"
    And I should see "Updated question text"
    And I should not see "Original question text"

  Scenario: delete my question
    When I press "Delete"
    Then I should see "Question deleted successfully!"
    And I should not see "Original question text"
    And I should see "No questions submitted yet"

  Scenario: cannot edit another student's question
    Given a student user exists with UNI "student456" and password "password123"
    And I am on the office hours home page
    When I press "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "student456"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    And I follow "Show this office hour" for "Math 101"
    Then I should see "Original question text"
    And I should not see "Edit"
    And I should not see "Delete"

