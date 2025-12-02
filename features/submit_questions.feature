Feature: submit questions for office hours

  Background:
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name        | instructor    | day       | start_time | end_time | location    | ta_uni |
      | Engineering SaaS   | Junfeng Yang  | Tuesday   | 3:00PM     | 5:00PM   | Zoom        | yj123 |
      | Data Structures    | Paul Blaer    | Wednesday | 2:00PM     | 4:00PM   | Lehman 301  | pb123 |
    And I am on the home page
    And I sign in as "student123" with password "password123"
    Then 2 seed office hours should exist

  Scenario: submit a question
    When I click "Show this office hour" for "Engineering SaaS"
    Then I should be viewing the office hour details for course "Engineering SaaS"
    And I should see "Submit a Question"
    And I should see "Previous Questions"
    And I should see "No questions submitted yet. Be the first to ask!"
    When I fill in "question_question_text" with "How do I implement authentication in Rails?"
    And I press "Submit Question"
    Then I should see "Question submitted successfully!"
    And I should see "How do I implement authentication in Rails?"

  Scenario: submit multiple questions
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with "First question"
    And I press "Submit Question"
    When I fill in "question_question_text" with "Second question"
    And I press "Submit Question"
    Then I should see "First question"
    And I should see "Second question"

  Scenario: submit empty question
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with ""
    And I press "Submit Question"
    Then I should see "Failed to submit question. Please try again."

  Scenario: view different office hour questions
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with "Question A"
    And I press "Submit Question"
    When I click "Back to Office Hours"
    And I click "Show this office hour" for "Data Structures"
    Then I should not see "Question A"
    And I should see "No questions submitted yet"
