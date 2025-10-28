Feature: display list of office hours sorted by different criteria

  As a student looking for help
  So that I can quickly browse office hours based on my preferences
  I want to see office hours sorted by course name, instructor, day, or start time

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

Scenario: sort office hours alphabetically by course name
  When I select "Course" from "sort_by"
  And I press "Refresh"
  Then I should see "Advanced Programming" before "Art Humanities"
  And I should see "Buddhism" before "Data Structures"
  And I should see "Discrete Mathematics" before "Engineering SaaS"

Scenario: sort office hours by day and time
  When I select "Day & Time" from "sort_by"
  And I press "Refresh"
  Then I should see "Advanced Programming" before "Discrete Mathematics"
  And I should see "Buddhism" before "Engineering SaaS"
  And I should see "Data Structures" before "Linear Algebra"

Scenario: sort office hours by instructor
  When I select "Instructor" from "sort_by"
  And I press "Refresh"
  Then I should see "Ansaf Salleb" before "Daniel Bauer"
  And I should see "Daniel Bauer" before "George Dragomir"