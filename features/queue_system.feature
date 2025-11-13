Feature: virtual queue for office hours
  As a student
  So that I can get help in order
  I want to join and leave a queue for office hours

  As a TA
  So that I can manage students seeking help
  I want to start, manage, and close the queue

  Background: office hours exist
    Given the following office hours exist:
      | course_name | instructor | day      | start_time | end_time | location | ta_uni |
      | Math 101    | Dr. Jones  | Tuesday  | 2:00PM     | 4:00PM   | Room 201 | tj123  |

  Scenario: student joins queue when queue is active
    Given a TA user exists with UNI "tj123" and password "password123"
    And a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "tj123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    And I press "Start Queue"
    Then I should see "Queue Active"
    When I press "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    Then I should see "Queue is Live!"
    When I press "Join Queue"
    Then I should see "You are in the queue at position"
    And I should see "Leave Queue"

  Scenario: student leaves queue
    Given a TA user exists with UNI "tj123" and password "password123"
    And a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "tj123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    And I press "Start Queue"
    When I press "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    And I press "Join Queue"
    Then I should see "Leave Queue"
    When I press "Leave Queue"
    Then I should see "You have left the queue"
    And I should see "Join Queue"

  Scenario: TA starts and closes queue
    Given a TA user exists with UNI "tj123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "tj123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    Then I should see "Queue Inactive"
    When I press "Start Queue"
    Then I should see "Queue Active"
    And I should see "Close Queue"
    When I press "Close Queue"
    Then I should see "Queue has been closed"
    And I should see "Start Queue"

  Scenario: TA removes student from queue
    Given a TA user exists with UNI "tj123" and password "password123"
    And a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "tj123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    And I press "Start Queue"
    When I press "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    And I press "Join Queue"
    When I press "Log out"
    And I follow "Sign in"
    And I fill in "UNI" with "tj123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    Then I should see "student123"
    When I press "Remove"
    Then I should see "Student removed from queue"
    And I should not see "student123"

  Scenario: student cannot join inactive queue
    Given a student user exists with UNI "student123" and password "password123"
    And I am on the office hours home page
    When I follow "Sign in"
    And I fill in "UNI" with "student123"
    And I fill in "Password" with "password123"
    And I press "Log in"
    And I follow "Show this office hour" for "Math 101"
    Then I should see "The queue is not currently active"
    And I should not see "Join Queue"

