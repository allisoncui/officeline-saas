Feature: manage questions

  Background:
    Given a student user exists with UNI "student123" and password "password123"
    And a student user exists with UNI "student456" and password "password123"
    And the following office hours exist:
      | course_name | instructor | day     | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday | 2:00PM     | 4:00PM   | Room 201 | tj123 |
    And I am on the home page
    And I sign in as "student123" with password "password123"
    And I view the office hour for "Math 101"
    And I fill in "question_question_text" with "Original question"
    And I press "Submit Question"

  Scenario: edit my question
    When I follow "Edit"
    Then I should be on the edit question page
    And I should see "Original question"
    When I fill in "question_question_text" with "Updated question"
    And I press "Update Question"
    Then I should see "Question updated successfully!"
    And I should see "Updated question"
    And I should not see "Original question"

  Scenario: delete my question
    When I press "Delete"
    Then I should see "Question deleted successfully!"
    And I should see "No questions submitted yet"

  Scenario: another student cannot edit my question
    When I follow "Log out"
    And I sign in as "student456" with password "password123"
    And I view the office hour for "Math 101"
    Then I should see "Original question"
    And I should not see "Edit"
    And I should not see "Delete"
