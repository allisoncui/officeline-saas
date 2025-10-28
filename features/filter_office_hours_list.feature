Feature: display list of office hours filtered by day of week
  As a busy student
  So that I can quickly find office hours on days I'm available
  I want to see office hours matching only certain days

Background: office hours have been added to database
  Given the following office hours exist:
  | course_name                    | instructor            | day       | start_time | end_time | location          |
  | Engineering SaaS               | Junfeng Yang          | Tuesday   | 3:00PM     | 5:00PM   | Zoom              |
  | Advanced Programming           | Jae Woo Lee           | Monday    | 1:00PM     | 3:00PM   | Pupin 301         |
  | Data Structures                | Paul Blaer            | Wednesday | 2:00PM     | 4:00PM   | Lehman 301        |
  | Data Structures                | Paul Blaer            | Thursday  | 10:00AM    | 12:00PM  | IAB 417           |
  | Buddhism                       | Michael Como          | Tuesday   | 8:00AM     | 10:00AM  | Zoom              |
  | Art Humanities                 | Ioannis Mylonopoulos  | Tuesday   | 5:00PM     | 7:00PM   | Schermerhorn 608  |
  | Intermediate Macroeconomics    | Irasema Alonso        | Thursday  | 1:00PM     | 3:00PM   | Uris 301          |
  | Natural Language Processing    | Daniel Bauer          | Wednesday | 2:00PM     | 4:00PM   | NOCO 501          |
  | Discrete Mathematics           | Ansaf Salleb          | Monday    | 4:00PM     | 6:00PM   | Pupin 428         |
  | Linear Algebra                 | George Dragomir       | Friday    | 12:00PM    | 2:00PM   | Math 312          |

  And I am on the office hours home page
  Then 10 seed office hours should exist

Scenario: restrict to office hours on "Monday" or "Tuesday"
  When I check the following days: Monday, Tuesday
  And I uncheck the following days: Wednesday, Thursday, Friday
  And I press "Refresh"
  Then I should see "Advanced Programming"
  And I should see "Engineering SaaS"
  And I should see "Buddhism"
  And I should see "Art Humanities"
  And I should see "Discrete Mathematics"
  And I should not see "Data Structures"
  And I should not see "Linear Algebra"

Scenario: all days selected
  When I check the following days: Monday, Tuesday, Wednesday, Thursday, Friday
  And I press "Refresh"
  Then I should see all of the office hours