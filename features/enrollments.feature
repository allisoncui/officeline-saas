Feature: enroll in office hours (save classes)

  Background:
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name        | instructor      | day     | start_time | end_time | location |
      | Engineering SaaS   | Junfeng Yang    | Tuesday | 3:00PM     | 5:00PM   | Zoom     |
    And I am on the home page
    And I sign in as "student123" with password "password123"

  Scenario: save a class
    When I press "Save Class" for "Engineering SaaS"
    Then I should see "Saved" for "Engineering SaaS"

  Scenario: remove a class
    When I press "Save Class" for "Engineering SaaS"
    And I press "Remove Class" for "Engineering SaaS"
    Then I should see "Save Class" for "Engineering SaaS"
