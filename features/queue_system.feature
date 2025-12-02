Feature: virtual queue for office hours

  Background:
    Given the following office hours exist:
      | course_name | instructor | day     | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday | 2:00PM     | 4:00PM   | Room 201 | tj123 |
    And I am on the home page

  Scenario: student joins queue when queue is active
    Given a TA user exists with UNI "tj123" and password "password123"
    And a student user exists with UNI "student123" and password "password123"
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    And I click "Show this office hour" for "Math 101"
    And I press "Start Queue"
    Then I should see "Queue Active"
    When I follow "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    And I click "Show this office hour" for "Math 101"
    Then I should see "Queue is Live!"
    When I press "Join Queue"
    Then I should see "You are in the queue at position"

  Scenario: student leaves queue
    Given a TA user exists with UNI "tj123" and password "password123"
    And a student user exists with UNI "student123" and password "password123"
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I press "Continue"
    And I fill in "Password" with "password123"
    And I press "Sign In"
    And I click "Show this office hour" for "Math 101"
    And I press "Start Queue"
    When I follow "Log out"
    And I sign in as "student123" with password "password123"
    And I click "Show this office hour" for "Math 101"
    And I press "Join Queue"
    Then I should see "Leave Queue"
    When I press "Leave Queue"
    Then I should see "You have left the queue"

  Scenario: TA starts and closes queue
    Given a TA user exists with UNI "tj123" and password "password123"
    When I sign in as "tj123" with password "password123"
    And I click "Show this office hour" for "Math 101"
    Then I should see "Queue Inactive"
    When I press "Start Queue"
    Then I should see "Queue Active"
    And I should see "Close Queue"
    When I press "Close Queue"
    Then I should see "Queue has been closed"
