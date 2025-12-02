Feature: display list of office hours filtered by day

  Background:
    Given a student user exists with UNI "student123" and password "password123"
    And the following office hours exist:
      | course_name                 | instructor         | day       | start_time | end_time | location        | ta_uni |
      | Engineering SaaS            | Junfeng Yang       | Tuesday   | 3:00PM     | 5:00PM   | Zoom            | y001   |
      | Advanced Programming        | Jae Woo Lee        | Monday    | 1:00PM     | 3:00PM   | Pupin 301       | y002   |
      | Data Structures             | Paul Blaer         | Wednesday | 2:00PM     | 4:00PM   | Lehman 301      | y003   |
      | Data Structures             | Paul Blaer         | Thursday  | 10:00AM    | 12:00PM  | IAB 417         | y004   |
      | Buddhism                    | Michael Como       | Tuesday   | 8:00AM     | 10:00AM  | Zoom            | y005   |
      | Art Humanities              | Ioannis Mylonopoulos| Tuesday  | 5:00PM     | 7:00PM   | Schermerhorn 608| y006   |
      | Intermediate Macroeconomics | Irasema Alonso     | Thursday  | 1:00PM     | 3:00PM   | Uris 301        | y007   |
      | Natural Language Processing | Daniel Bauer       | Wednesday | 2:00PM     | 4:00PM   | NOCO 501        | y008   |
      | Discrete Mathematics        | Ansaf Salleb       | Monday    | 4:00PM     | 6:00PM   | Pupin 428       | y009   |
      | Linear Algebra              | George Dragomir    | Friday    | 12:00PM    | 2:00PM   | Math 312        | y010   |
    And I am on the home page
    And I sign in as "student123" with password "password123"
    Then 10 seed office hours should exist

  Scenario: filter for Monday or Tuesday
    When I check "Monday"
    And I check "Tuesday"
    And I uncheck "Wednesday"
    And I uncheck "Thursday"
    And I uncheck "Friday"
    And I press "Refresh"
    Then I should see "Advanced Programming"
    And I should see "Engineering SaaS"
    And I should see "Buddhism"
    And I should see "Art Humanities"
    And I should see "Discrete Mathematics"
    And I should not see "Data Structures"
    And I should not see "Linear Algebra"

  Scenario: all days selected
    When I check "Monday"
    And I check "Tuesday"
    And I check "Wednesday"
    And I check "Thursday"
    And I check "Friday"
    And I press "Refresh"
    Then I should see all of the office hours
