Feature: submit questions for office hours
  As a student
  So that I can get help with specific topics
  I want to submit questions for office hours

Background: office hours exist in the database
  Given the following office hours exist:
  | course_name | instructor    | day      | start_time | end_time | location |
  | Engineering SaaS | Junfeng Yang | Tuesday | 3:00PM    | 5:00PM  | Zoom     |
  | Data Structures  | Paul Blaer   | Wednesday | 2:00PM | 4:00PM | Lehman 301 |

  And I am on the office hours home page
  Then 2 seed office hours should exist

  Scenario: submit a question for an office hour
    When I click "Show this office hour" for "Engineering SaaS"
    Then I should be viewing the office hour details for course "Engineering SaaS"
    And I should see "Submit a Question"
    And I should see "Previous Questions"
    And I should see "No questions submitted yet. Be the first to ask!"

    When I fill in "question_question_text" with "How do I implement authentication in Rails?"
    And I press "Submit Question"
    Then I should see "Question submitted successfully!"
    And I should see "How do I implement authentication in Rails?"
    And I should see "Submitted:"

  Scenario: submit multiple questions for the same office hour
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with "First question about authentication"
    And I press "Submit Question"
    Then I should see "Question submitted successfully!"

    When I fill in "question_question_text" with "Second question about database design"
    And I press "Submit Question"
    Then I should see "Question submitted successfully!"
    And I should see "First question about authentication"
    And I should see "Second question about database design"

  Scenario: submit question with empty text
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with ""
    And I press "Submit Question"
    Then I should see "Failed to submit question. Please try again."

  Scenario: view questions for different office hours
    Given I am viewing the office hour details for course "Engineering SaaS"
    When I fill in "question_question_text" with "Question for Engineering SaaS"
    And I press "Submit Question"
    Then I should see "Question submitted successfully!"

    When I click "Back to office hours"
    And I click "Show this office hour" for "Data Structures"
    Then I should be viewing the office hour details for course "Data Structures"
    And I should see "No questions submitted yet. Be the first to ask!"
    And I should not see "Question for Engineering SaaS"
