Feature: calendar view of office hours
  As a student
  So that I can see office hours in a visual calendar format
  I want to toggle between list and calendar views

  Background:
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name          | instructor      | day       | start_time | end_time | location     | ta_uni |
      | Engineering SaaS     | Junfeng Yang    | Tuesday   | 3:00PM     | 5:00PM   | Zoom         | ta001 |
      | Advanced Programming | Jae Woo Lee     | Monday    | 1:00PM     | 3:00PM   | Pupin 301    | ta002 |
      | Data Structures      | Paul Blaer      | Wednesday | 2:00PM     | 4:00PM   | Lehman 301   | ta003 |
    And I am on the home page
    And I sign in as "student123" with password "password123"

  Scenario: switch to calendar view
    When I follow "My Hours"
    And I check "calendar_toggle"
    And I press "Refresh"
    Then I should see the calendar view
    And I should see "Engineering SaaS"
    And I should see "Advanced Programming"
    And I should see "Data Structures"

  Scenario: switch back to list view
    When I follow "My Hours"
    And I check "calendar_toggle"
    And I press "Refresh"
    Then I should see the calendar view
    When I uncheck "calendar_toggle"
    And I press "Refresh"
    Then I should see office hours in list format
